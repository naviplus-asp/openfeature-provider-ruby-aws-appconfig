# frozen_string_literal: true

require "aws-sdk-appconfigdata"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          # Client for AWS AppConfigData API
          # Handles configuration retrieval using AWS AppConfigData SDK
          # Manages session tokens and error handling for configuration access
          class Client
            # Error handler mapping for different exception types
            # Maps AWS SDK exceptions and JSON parsing errors to handler methods
            ERROR_HANDLERS = {
              ::Aws::AppConfigData::Errors::ResourceNotFoundException => :handle_resource_not_found_error,
              ::Aws::AppConfigData::Errors::ThrottlingException => :handle_throttling_error,
              ::Aws::AppConfigData::Errors::InvalidParameterException => :handle_invalid_parameter_exception,
              JSON::ParserError => :handle_parser_error
            }.freeze

            # Initializes the AWS AppConfigData client
            # @param application [String] AWS AppConfig application name
            # @param environment [String] AWS AppConfig environment name
            # @param configuration_profile [String] AWS AppConfig configuration profile name
            # @param options [Hash] Client configuration options
            # @option options [String] :region AWS region (default: "us-east-1")
            # @option options [Aws::Credentials] :credentials AWS credentials
            # @option options [Aws::AppConfigData::Client] :client Custom AWS AppConfigData client
            # @option options [String] :endpoint_url Custom endpoint URL for testing
            def initialize(application:, environment:, configuration_profile:, options: {})
              @application = application
              @environment = environment
              @configuration_profile = configuration_profile
              client_config = build_client_config(options)
              @client = options[:client] || ::Aws::AppConfigData::Client.new(client_config)
              @session_token = nil
            end

            # Retrieves configuration value for the specified flag key
            # @param flag_key [String] The feature flag key to retrieve
            # @return [Object] The configuration value for the flag key
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def get_configuration(flag_key)
              ensure_valid_session
              response = fetch_configuration_response
              parse_configuration_response(response, flag_key)
            rescue StandardError => e
              handle_configuration_error(e, flag_key)
            end

            private

            # Builds AWS client configuration from options
            # @param options [Hash] Client configuration options
            # @return [Hash] AWS client configuration hash
            def build_client_config(options)
              client_config = {
                region: options[:region] || "us-east-1",
                credentials: options[:credentials]
              }
              client_config[:endpoint] = options[:endpoint_url] if options[:endpoint_url]
              client_config
            end

            # Fetches configuration response from AWS AppConfigData API
            # @return [Aws::AppConfigData::Types::GetLatestConfigurationResponse] Configuration response
            def fetch_configuration_response
              @client.get_latest_configuration(
                configuration_token: @session_token
              )
            end

            # Parses configuration response and extracts flag value
            # @param response [Aws::AppConfigData::Types::GetLatestConfigurationResponse] Configuration response
            # @param flag_key [String] The feature flag key to extract
            # @return [Object] The configuration value for the flag key
            def parse_configuration_response(response, flag_key)
              config_data = JSON.parse(response.configuration.read)
              config_data[flag_key]
            end

            # Handles configuration errors by delegating to appropriate error handler
            # @param error [StandardError] The error that occurred
            # @param flag_key [String] The flag key that was being processed
            # @raise [StandardError] Re-raised or transformed error
            def handle_configuration_error(error, flag_key)
              error_handler = get_error_handler(error)
              error_handler.call(error, flag_key)
            end

            # Gets the appropriate error handler for the given error
            # @param error [StandardError] The error to get handler for
            # @return [Method] The error handler method
            def get_error_handler(error)
              handler_method = ERROR_HANDLERS[error.class]
              method(handler_method || :re_raise_error)
            end

            # Default error handler that re-raises the original error
            # @param error [StandardError] The error to re-raise
            # @param _flag_key [String] Unused flag key parameter
            # @raise [StandardError] The original error
            def re_raise_error(error, _flag_key)
              raise error
            end

            # Handles resource not found errors
            # @param error [Aws::AppConfigData::Errors::ResourceNotFoundException] The resource not found error
            # @raise [StandardError] Transformed error message
            def handle_resource_not_found_error(error)
              raise StandardError, "Configuration not found: #{error.message}"
            end

            # Handles throttling errors
            # @param error [Aws::AppConfigData::Errors::ThrottlingException] The throttling error
            # @raise [StandardError] Transformed error message
            def handle_throttling_error(error)
              raise StandardError, "Request throttled: #{error.message}"
            end

            # Handles JSON parser errors
            # @param error [JSON::ParserError] The JSON parsing error
            # @raise [StandardError] Transformed error message
            def handle_parser_error(error)
              raise StandardError, "Failed to parse configuration: #{error.message}"
            end

            # Handles invalid parameter exceptions, including session expiry
            # @param exception [Aws::AppConfigData::Errors::InvalidParameterException] The invalid parameter exception
            # @param flag_key [String] The flag key being processed
            # @return [Object] Configuration value after session refresh
            # @raise [StandardError] When error is not session-related
            def handle_invalid_parameter_exception(exception, flag_key)
              unless session_expired_error?(exception.message)
                raise StandardError, "Invalid parameter error: #{exception.message}"
              end

              refresh_session
              get_configuration(flag_key)
            end

            # Ensures a valid session exists before making requests
            def ensure_valid_session
              create_session if @session_token.nil?
            end

            # Creates a new configuration session
            # @raise [StandardError] When session creation fails
            def create_session
              response = @client.start_configuration_session(
                application_identifier: @application,
                environment_identifier: @environment,
                configuration_profile_identifier: @configuration_profile
              )
              @session_token = response.initial_configuration_token
            rescue ::Aws::AppConfigData::Errors::ResourceNotFoundException => e
              raise StandardError, "Configuration session not found: #{e.message}"
            rescue ::Aws::AppConfigData::Errors::ThrottlingException => e
              raise StandardError, "Session creation throttled: #{e.message}"
            end

            # Refreshes the current session by clearing token and creating new session
            def refresh_session
              @session_token = nil
              create_session
            end

            # Checks if an error message indicates session expiry
            # @param message [String] The error message to check
            # @return [Boolean] True if the error indicates session expiry
            def session_expired_error?(message)
              message.include?("expired") || message.include?("session")
            end
          end
        end
      end
    end
  end
end
