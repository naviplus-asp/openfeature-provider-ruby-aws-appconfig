# frozen_string_literal: true

require "open_feature/sdk"
require "aws-sdk-appconfig"
require "json"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          # OpenFeature provider for AWS AppConfig
          # Handles feature flag resolution using AWS AppConfig service
          class Provider
            include OpenFeature::SDK::Provider

            attr_reader :client, :application, :environment, :configuration_profile

            # Initializes the AWS AppConfig provider
            # @param config [Hash] Configuration hash containing AWS AppConfig settings
            # @option config [String] :application Required AWS AppConfig application name
            # @option config [String] :environment Required AWS AppConfig environment name
            # @option config [String] :configuration_profile Required AWS AppConfig configuration profile name
            # @option config [String] :region AWS region (default: "us-east-1")
            # @option config [Aws::Credentials] :credentials AWS credentials
            # @option config [String] :endpoint_url Custom endpoint URL for testing
            # @option config [Aws::AppConfig::Client] :client Custom AWS AppConfig client
            # @raise [ArgumentError] When required parameters are missing
            def initialize(config = {})
              @application = config[:application] || raise(ArgumentError, "application is required")
              @environment = config[:environment] || raise(ArgumentError, "environment is required")
              @configuration_profile = config[:configuration_profile] || raise(ArgumentError,
                                                                               "configuration_profile is required")

              client_config = {
                region: config[:region] || "us-east-1",
                credentials: config[:credentials]
              }

              # Add endpoint URL for LocalStack testing
              client_config[:endpoint] = config[:endpoint_url] if config[:endpoint_url]

              @client = config[:client] || ::Aws::AppConfig::Client.new(client_config)
            end

            # Resolves a boolean feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the boolean value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_boolean_value(flag_key, context = nil)
              value = get_configuration_value(flag_key, context)
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: convert_to_boolean(value),
                variant: "default",
                reason: "DEFAULT"
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            rescue StandardError => e
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: false,
                variant: "error",
                reason: "ERROR",
                error_code: "GENERAL",
                error_message: e.message
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            end

            # Resolves a string feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the string value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_string_value(flag_key, context = nil)
              value = get_configuration_value(flag_key, context)
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: convert_to_string(value),
                variant: "default",
                reason: "DEFAULT"
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            rescue StandardError => e
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: "",
                variant: "error",
                reason: "ERROR",
                error_code: "GENERAL",
                error_message: e.message
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            end

            # Resolves a numeric feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the numeric value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_number_value(flag_key, context = nil)
              value = get_configuration_value(flag_key, context)
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: convert_to_number(value),
                variant: "default",
                reason: "DEFAULT"
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            rescue StandardError => e
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: 0,
                variant: "error",
                reason: "ERROR",
                error_code: "GENERAL",
                error_message: e.message
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            end

            # Resolves an object feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the object value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_object_value(flag_key, context = nil)
              value = get_configuration_value(flag_key, context)
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: convert_to_object(value),
                variant: "default",
                reason: "DEFAULT"
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            rescue StandardError => e
              resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: {},
                variant: "error",
                reason: "ERROR",
                error_code: "GENERAL",
                error_message: e.message
              )
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            end

            private

            # Retrieves configuration value from AWS AppConfig for the given flag key
            # @param flag_key [String] The feature flag key to retrieve
            # @param _context [OpenFeature::EvaluationContext, nil] Unused evaluation context
            # @return [Object, nil] The configuration value or nil if not found
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def get_configuration_value(flag_key, _context)
              response = @client.get_configuration(
                application: @application,
                environment: @environment,
                configuration_profile: @configuration_profile
              )

              # Parse the configuration content
              config_data = JSON.parse(response.content.read)
              config_data[flag_key]
            rescue ::Aws::AppConfig::Errors::ResourceNotFoundException => e
              raise StandardError, "Configuration not found: #{e.message}"
            rescue ::Aws::AppConfig::Errors::ThrottlingException => e
              raise StandardError, "Request throttled: #{e.message}"
            rescue JSON::ParserError => e
              raise StandardError, "Failed to parse configuration: #{e.message}"
            end

            # Converts a value to boolean type
            # @param value [Object] The value to convert
            # @return [Boolean] The converted boolean value
            def convert_to_boolean(value)
              case value
              when true, false
                value
              when String
                value.downcase == "true"
              when Numeric
                value != 0
              else
                false
              end
            end

            # Converts a value to string type
            # @param value [Object] The value to convert
            # @return [String] The converted string value
            def convert_to_string(value)
              value.to_s
            end

            # Converts a value to numeric type
            # @param value [Object] The value to convert
            # @return [Numeric] The converted numeric value (Float for string inputs)
            def convert_to_number(value)
              case value
              when Numeric
                value
              when String
                Float(value)
              else
                0
              end
            rescue ArgumentError
              0
            end

            # Converts a value to object type (Hash)
            # @param value [Object] The value to convert
            # @return [Hash] The converted hash value
            def convert_to_object(value)
              case value
              when Hash
                value
              when String
                JSON.parse(value)
              else
                {}
              end
            rescue JSON::ParserError
              {}
            end
          end
        end
      end
    end
  end
end
