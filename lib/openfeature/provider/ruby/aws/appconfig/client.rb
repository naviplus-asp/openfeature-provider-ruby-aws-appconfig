# frozen_string_literal: true

require "aws-sdk-appconfigdata"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class Client
            ERROR_HANDLERS = {
              ::Aws::AppConfigData::Errors::ResourceNotFoundException => :handle_resource_not_found_error,
              ::Aws::AppConfigData::Errors::ThrottlingException => :handle_throttling_error,
              ::Aws::AppConfigData::Errors::InvalidParameterException => :handle_invalid_parameter_exception,
              JSON::ParserError => :handle_parser_error
            }.freeze

            def initialize(application:, environment:, configuration_profile:, options: {})
              @application = application
              @environment = environment
              @configuration_profile = configuration_profile
              client_config = build_client_config(options)
              @client = options[:client] || ::Aws::AppConfigData::Client.new(client_config)
              @session_token = nil
            end

            def get_configuration(flag_key)
              ensure_valid_session
              response = fetch_configuration_response
              parse_configuration_response(response, flag_key)
            rescue StandardError => e
              handle_configuration_error(e, flag_key)
            end

            private

            def build_client_config(options)
              client_config = {
                region: options[:region] || "us-east-1",
                credentials: options[:credentials]
              }
              client_config[:endpoint] = options[:endpoint_url] if options[:endpoint_url]
              client_config
            end

            def fetch_configuration_response
              @client.get_latest_configuration(
                configuration_token: @session_token
              )
            end

            def parse_configuration_response(response, flag_key)
              config_data = JSON.parse(response.configuration.read)
              config_data[flag_key]
            end

            def handle_configuration_error(error, flag_key)
              error_handler = get_error_handler(error)
              error_handler.call(error, flag_key)
            end

            def get_error_handler(error)
              handler_method = ERROR_HANDLERS[error.class]
              method(handler_method || :re_raise_error)
            end

            def re_raise_error(error, _flag_key)
              raise error
            end

            def handle_resource_not_found_error(error)
              raise StandardError, "Configuration not found: #{error.message}"
            end

            def handle_throttling_error(error)
              raise StandardError, "Request throttled: #{error.message}"
            end

            def handle_parser_error(error)
              raise StandardError, "Failed to parse configuration: #{error.message}"
            end

            def handle_invalid_parameter_exception(exception, flag_key)
              unless session_expired_error?(exception.message)
                raise StandardError, "Invalid parameter error: #{exception.message}"
              end

              refresh_session
              get_configuration(flag_key)
            end

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
