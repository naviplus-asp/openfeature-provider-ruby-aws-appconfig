# frozen_string_literal: true

require "aws-sdk-appconfig"
require "aws-sdk-appconfigdata"
require "json"
require "securerandom"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          # Helper class for LocalStack integration testing
          # Provides utilities to set up and manage AWS AppConfig resources in LocalStack
          class LocalstackHelper
            attr_reader :client

            # Initializes the LocalStack helper for AWS AppConfig testing
            # @param endpoint_url [String, nil] LocalStack endpoint URL (default: nil for AWS)
            def initialize(endpoint_url = nil)
              config = {
                region: "us-east-1",
                credentials: Aws::Credentials.new("test", "test")
              }
              config[:endpoint] = endpoint_url if endpoint_url

              @client = Aws::AppConfig::Client.new(config)
            end

            # Creates an AWS AppConfig application
            # @param name [String] The application name
            # @return [Aws::AppConfig::Types::Application] The created application
            def create_application(name)
              @client.create_application(name: name)
            rescue Aws::AppConfig::Errors::ConflictException
              # Application already exists
              @client.get_application(application_id: name)
            end

            # Creates an AWS AppConfig environment
            # @param application_id [String] The application ID
            # @param environment_name [String] The environment name
            # @return [Aws::AppConfig::Types::Environment] The created environment
            def create_environment(application_id, environment_name)
              @client.create_environment(
                application_id: application_id,
                name: environment_name
              )
            rescue Aws::AppConfig::Errors::ConflictException
              # Environment already exists
              @client.get_environment(
                application_id: application_id,
                environment_id: environment_name
              )
            end

            # Creates an AWS AppConfig configuration profile
            # @param application_id [String] The application ID
            # @param profile_name [String] The configuration profile name
            # @param _content_type [String] The content type (default: "application/json")
            # @return [Aws::AppConfig::Types::ConfigurationProfile] The created configuration profile
            def create_configuration_profile(application_id, profile_name, _content_type = "application/json")
              @client.create_configuration_profile(
                application_id: application_id,
                name: profile_name,
                location_uri: "hosted",
                type: "AWS.Freeform"
              )
            rescue Aws::AppConfig::Errors::ConflictException
              # Configuration profile already exists
              @client.get_configuration_profile(
                application_id: application_id,
                configuration_profile_id: profile_name
              )
            end

            # Creates a hosted configuration version
            # @param application_id [String] The application ID
            # @param profile_name [String] The configuration profile name
            # @param content [String] The configuration content
            # @param content_type [String] The content type (default: "application/json")
            # @return [Aws::AppConfig::Types::HostedConfigurationVersion] The created configuration version
            def create_hosted_configuration_version(application_id, profile_name, content,
                                                    content_type = "application/json")
              @client.create_hosted_configuration_version(
                application_id: application_id,
                configuration_profile_id: profile_name,
                content: content,
                content_type: content_type
              )
            end

            # Creates a deployment strategy
            # @param name [String] The deployment strategy name
            # @param deployment_duration_in_minutes [Integer] Deployment duration in minutes (default: 0)
            # @param growth_factor [Integer] Growth factor percentage (default: 100)
            # @return [Aws::AppConfig::Types::DeploymentStrategy] The created deployment strategy
            def create_deployment_strategy(name, deployment_duration_in_minutes = 0, growth_factor = 100)
              @client.create_deployment_strategy(
                name: name,
                deployment_duration_in_minutes: deployment_duration_in_minutes,
                growth_factor: growth_factor,
                replicate_to: "NONE"
              )
            rescue Aws::AppConfig::Errors::ConflictException
              # Deployment strategy already exists
              @client.get_deployment_strategy(deployment_strategy_id: name)
            end

            # Starts a deployment
            # @param application_id [String] The application ID
            # @param environment_name [String] The environment name
            # @param profile_name [String] The configuration profile name
            # @param strategy_name [String] The deployment strategy name
            # @return [Aws::AppConfig::Types::Deployment] The started deployment
            def start_deployment(application_id, environment_name, profile_name, strategy_name)
              @client.start_deployment(
                application_id: application_id,
                environment_id: environment_name,
                configuration_profile_id: profile_name,
                configuration_version: "1",
                deployment_strategy_id: strategy_name
              )
            end

            # Waits for a deployment to complete
            # @param application_id [String] The application ID
            # @param environment_name [String] The environment name
            # @param deployment_number [Integer] The deployment number
            # @raise [RuntimeError] When deployment fails
            def wait_for_deployment(application_id, environment_name, deployment_number)
              loop do
                deployment = @client.get_deployment(
                  application_id: application_id,
                  environment_id: environment_name,
                  deployment_number: deployment_number
                )

                case deployment.state
                when "COMPLETE"
                  break
                when "FAILED"
                  raise "Deployment failed: #{deployment.state}"
                else
                  sleep 1
                end
              end
            end

            # Sets up a complete test configuration in AWS AppConfig
            # @param application_name [String] The application name
            # @param environment_name [String] The environment name
            # @param profile_name [String] The configuration profile name
            # @param config_data [Hash] The configuration data to deploy
            # @return [Hash] Hash containing the created resource IDs
            def setup_test_configuration(application_name, environment_name, profile_name, config_data)
              # Create application
              app = create_application(application_name)

              # Create environment
              env = create_environment(app.id, environment_name)

              # Create configuration profile
              profile = create_configuration_profile(app.id, profile_name)

              # Create configuration version
              config_content = JSON.generate(config_data)
              version = create_hosted_configuration_version(app.id, profile_name, config_content)

              # Create deployment strategy
              strategy = create_deployment_strategy("test-strategy")

              # Start deployment
              deployment = start_deployment(app.id, environment_name, profile_name, strategy.id)

              # Wait for deployment to complete
              wait_for_deployment(app.id, environment_name, deployment.deployment_number)

              {
                application_id: app.id,
                environment_id: env.id,
                configuration_profile_id: profile.id,
                configuration_version: version.version_number
              }
            end

            # Cleans up test resources by deleting environments, configuration profiles, and application
            # @param application_id [String] The application ID to cleanup
            def cleanup_test_resources(application_id)
              # List and delete environments
              environments = @client.list_environments(application_id: application_id)
              environments.items.each do |env|
                @client.delete_environment(
                  application_id: application_id,
                  environment_id: env.id
                )
              rescue StandardError => e
                puts "Warning: Could not delete environment #{env.id}: #{e.message}"
              end

              # List and delete configuration profiles
              profiles = @client.list_configuration_profiles(application_id: application_id)
              profiles.items.each do |profile|
                @client.delete_configuration_profile(
                  application_id: application_id,
                  configuration_profile_id: profile.id
                )
              rescue StandardError => e
                puts "Warning: Could not delete configuration profile #{profile.id}: #{e.message}"
              end

              # Delete application
              @client.delete_application(application_id: application_id)
            rescue StandardError => e
              puts "Warning: Could not cleanup resources: #{e.message}"
            end
          end
        end
      end
    end
  end
end
