# frozen_string_literal: true

require "aws-sdk-appconfigdata"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class Client
            def initialize(application:, environment:, configuration_profile:, region: "us-east-1", credentials: nil,
                           client: nil, endpoint_url: nil)
              @application = application
              @environment = environment
              @configuration_profile = configuration_profile
              client_config = { region: region, credentials: credentials }
              client_config[:endpoint] = endpoint_url if endpoint_url
              @client = client || ::Aws::AppConfigData::Client.new(client_config)
              @session_token = nil
            end

            def get_configuration(flag_key)
              ensure_valid_session
              response = @client.get_latest_configuration(
                configuration_token: @session_token
              )
              config_data = JSON.parse(response.configuration.read)
              config_data[flag_key]
            rescue ::Aws::AppConfigData::Errors::ResourceNotFoundException => e
              raise StandardError, "Configuration not found: #{e.message}"
            rescue ::Aws::AppConfigData::Errors::ThrottlingException => e
              raise StandardError, "Request throttled: #{e.message}"
            rescue ::Aws::AppConfigData::Errors::InvalidParameterException => e
              raise StandardError, "Invalid parameter error: #{e.message}" unless session_expired_error?(e.message)

              refresh_session
              retry
            rescue JSON::ParserError => e
              raise StandardError, "Failed to parse configuration: #{e.message}"
            end

            private

            def ensure_valid_session
              create_session if @session_token.nil?
            end

            def create_session
              response = @client.start_configuration_session(
                application_identifier: @application,
                environment_identifier: @environment,
                configuration_profile_identifier: @configuration_profile
              )
              @session_token = response.initial_configuration_token
            end

            def refresh_session
              @session_token = nil
              create_session
            end

            def session_expired_error?(message)
              message.include?("expired") || message.include?("session")
            end
          end
        end
      end
    end
  end
end
