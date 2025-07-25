# frozen_string_literal: true

require "open_feature/sdk"
require "aws-sdk-appconfig"
require "json"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class Provider
            include OpenFeature::SDK::Provider

            attr_reader :client, :application, :environment, :configuration_profile

            def initialize(config = {})
              @application = config[:application] || raise(ArgumentError, "application is required")
              @environment = config[:environment] || raise(ArgumentError, "environment is required")
              @configuration_profile = config[:configuration_profile] || raise(ArgumentError,
                                                                               "configuration_profile is required")

              @client = config[:client] || Aws::AppConfig::Client.new(
                region: config[:region] || "us-east-1",
                credentials: config[:credentials]
              )
            end

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

            def get_configuration_value(flag_key, context)
              response = @client.get_configuration(
                application: @application,
                environment: @environment,
                configuration_profile: @configuration_profile
              )

              # Parse the configuration content
              config_data = JSON.parse(response.content.read)
              config_data[flag_key]
            rescue Aws::AppConfig::Errors::ResourceNotFoundException => e
              raise StandardError, "Configuration not found: #{e.message}"
            rescue Aws::AppConfig::Errors::ThrottlingException => e
              raise StandardError, "Request throttled: #{e.message}"
            rescue JSON::ParserError => e
              raise StandardError, "Failed to parse configuration: #{e.message}"
            end

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

            def convert_to_string(value)
              value.to_s
            end

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
