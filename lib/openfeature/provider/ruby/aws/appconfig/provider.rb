# frozen_string_literal: true

require "open_feature/sdk"
require "aws-sdk-appconfigdata"
require "json"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          # OpenFeature provider for AWS AppConfig
          # Handles feature flag resolution using AWS AppConfig service
          # Supports both simple flags and multi-variant flags
          class Provider
            include OpenFeature::SDK::Provider

            # Operator method mapping
            OPERATOR_METHODS = {
              "equals" => :equals_operator?,
              "not_equals" => :not_equals_operator?,
              "contains" => :contains_operator?,
              "not_contains" => :not_contains_operator?,
              "starts_with" => :starts_with_operator?,
              "ends_with" => :ends_with_operator?,
              "greater_than" => :greater_than_operator?,
              "greater_than_or_equal" => :greater_than_or_equal_operator?,
              "less_than" => :less_than_operator?,
              "less_than_or_equal" => :less_than_or_equal_operator?
            }.freeze

            attr_reader :client, :application, :environment, :configuration_profile

            # Initializes the AWS AppConfig provider
            # @param config [Hash] Configuration hash containing AWS AppConfig settings
            # @option config [String] :application Required AWS AppConfig application name
            # @option config [String] :environment Required AWS AppConfig environment name
            # @option config [String] :configuration_profile Required AWS AppConfig configuration profile name
            # @option config [String] :region AWS region (default: "us-east-1")
            # @option config [Aws::Credentials] :credentials AWS credentials
            # @option config [String] :endpoint_url Custom endpoint URL for testing
            # @option config [Aws::AppConfigData::Client] :client Custom AWS AppConfigData client
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

              # Add endpoint URL for testing
              client_config[:endpoint] = config[:endpoint_url] if config[:endpoint_url]

              # Use the new AppConfigData client instead of the deprecated AppConfig client
              @client = config[:client] || ::Aws::AppConfigData::Client.new(client_config)

              # Initialize session management
              @session_token = nil
              @session_expires_at = nil
            end

            # Resolves a boolean feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the boolean value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_boolean_value(flag_key:, context: nil)
              resolve_value(flag_key: flag_key, context: context, converter: :convert_to_boolean, default_value: false)
            end

            # Resolves a string feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the string value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_string_value(flag_key:, context: nil)
              resolve_value(flag_key: flag_key, context: context, converter: :convert_to_string, default_value: "")
            end

            # Common method to resolve feature flag values
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @param converter [Symbol] The conversion method to use
            # @param default_value [Object] The default value for errors
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_value(flag_key:, converter:, default_value:, context: nil)
              flag_data = get_configuration_value(flag_key, context)
              resolution_details = create_resolution_details(flag_data, context, converter, default_value)

              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            rescue StandardError => e
              resolution_details = create_error_resolution_details(default_value, e.message)
              OpenFeature::SDK::EvaluationDetails.new(
                flag_key: flag_key,
                resolution_details: resolution_details
              )
            end

            # Creates resolution details for a feature flag
            # @param flag_data [Object] The flag data from AWS AppConfig
            # @param context [OpenFeature::EvaluationContext, nil] Evaluation context
            # @param converter [Symbol] The conversion method to use
            # @param default_value [Object] The default value for errors
            # @return [OpenFeature::SDK::Provider::ResolutionDetails] Resolution details
            def create_resolution_details(flag_data, context, converter, default_value)
              if multi_variant_flag?(flag_data)
                create_multi_variant_resolution_details(flag_data, context, converter, default_value)
              else
                create_simple_resolution_details(flag_data, converter)
              end
            end

            # Creates resolution details for multi-variant flags
            # @param flag_data [Hash] The multi-variant flag data
            # @param context [OpenFeature::EvaluationContext, nil] Evaluation context
            # @param converter [Symbol] The conversion method to use
            # @param default_value [Object] The default value for errors
            # @return [OpenFeature::SDK::Provider::ResolutionDetails] Resolution details
            def create_multi_variant_resolution_details(flag_data, context, converter, default_value)
              variant = select_variant(flag_data, context)
              if variant
                value = send(converter, variant["value"])
                reason = determine_resolution_reason(flag_data, context, variant)
                OpenFeature::SDK::Provider::ResolutionDetails.new(
                  value: value,
                  variant: variant["name"] || "selected",
                  reason: reason
                )
              else
                create_error_resolution_details(default_value, "No matching variant found")
              end
            end

            # Creates resolution details for simple flags
            # @param flag_data [Object] The flag data
            # @param converter [Symbol] The conversion method to use
            # @return [OpenFeature::SDK::Provider::ResolutionDetails] Resolution details
            def create_simple_resolution_details(flag_data, converter)
              value = send(converter, flag_data)
              OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: value,
                variant: "default",
                reason: "DEFAULT"
              )
            end

            # Creates error resolution details
            # @param default_value [Object] The default value
            # @param error_message [String] The error message
            # @return [OpenFeature::SDK::Provider::ResolutionDetails] Error resolution details
            def create_error_resolution_details(default_value, error_message)
              OpenFeature::SDK::Provider::ResolutionDetails.new(
                value: default_value,
                variant: "error",
                reason: "ERROR",
                error_code: "GENERAL",
                error_message: error_message
              )
            end

            # Resolves a numeric feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the numeric value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_number_value(flag_key:, context: nil)
              resolve_value(flag_key: flag_key, context: context, converter: :convert_to_number, default_value: 0)
            end

            # Resolves an object feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the object value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_object_value(flag_key:, context: nil)
              resolve_value(flag_key: flag_key, context: context, converter: :convert_to_object, default_value: {})
            end

            # Required methods for OpenFeature SDK 0.4.0 compatibility
            def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
              result = resolve_boolean_value(flag_key: flag_key, context: evaluation_context)
              result.value
            rescue StandardError
              default_value
            end

            def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
              result = resolve_string_value(flag_key: flag_key, context: evaluation_context)
              result.value
            rescue StandardError
              default_value
            end

            def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
              result = resolve_number_value(flag_key: flag_key, context: evaluation_context)
              result.value
            rescue StandardError
              default_value
            end

            def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
              result = resolve_object_value(flag_key: flag_key, context: evaluation_context)
              result.value
            rescue StandardError
              default_value
            end

            private

            # Retrieves configuration value from AWS AppConfig using the new AppConfigData API
            # @param flag_key [String] The feature flag key to retrieve
            # @param _context [OpenFeature::EvaluationContext, nil] Unused evaluation context
            # @return [Object, nil] The configuration value or nil if not found
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def get_configuration_value(flag_key, _context)
              # Ensure we have a valid session
              ensure_valid_session

              # Get the latest configuration using the session token
              response = @client.get_latest_configuration(
                configuration_token: @session_token
              )

              # Parse the configuration content
              config_data = JSON.parse(response.configuration.read)
              config_data[flag_key]
            rescue ::Aws::AppConfigData::Errors::ResourceNotFoundException => e
              raise StandardError, "Configuration not found: #{e.message}"
            rescue ::Aws::AppConfigData::Errors::ThrottlingException => e
              raise StandardError, "Request throttled: #{e.message}"
            rescue ::Aws::AppConfigData::Errors::InvalidParameterException => _e
              # Session might be expired, try to refresh
              refresh_session
              retry
            rescue JSON::ParserError => e
              raise StandardError, "Failed to parse configuration: #{e.message}"
            end

            # Ensures we have a valid session token
            # @raise [StandardError] When session cannot be created
            def ensure_valid_session
              return if session_valid?

              create_session
            end

            # Checks if the current session is still valid
            # @return [Boolean] True if session is valid
            def session_valid?
              return false if @session_token.nil?
              return false if @session_expires_at.nil?

              Time.now < @session_expires_at
            end

            # Creates a new configuration session
            # @raise [StandardError] When session cannot be created
            def create_session
              response = @client.start_configuration_session(
                application_identifier: @application,
                environment_identifier: @environment,
                configuration_profile_identifier: @configuration_profile
              )

              @session_token = response.initial_configuration_token
              # Set session expiry to 1 hour from now (AWS sessions typically last 1 hour)
              @session_expires_at = Time.now + 3600
            rescue ::Aws::AppConfigData::Errors::ResourceNotFoundException => e
              raise StandardError, "Configuration session not found: #{e.message}"
            rescue ::Aws::AppConfigData::Errors::ThrottlingException => e
              raise StandardError, "Session creation throttled: #{e.message}"
            end

            # Refreshes the configuration session
            # @raise [StandardError] When session cannot be refreshed
            def refresh_session
              @session_token = nil
              @session_expires_at = nil
              create_session
            end

            # Checks if the flag data represents a multi-variant flag
            # @param flag_data [Object] The flag data to check
            # @return [Boolean] True if it's a multi-variant flag
            def multi_variant_flag?(flag_data)
              return false unless flag_data.is_a?(Hash)

              # Check for multi-variant flag structure
              flag_data.key?("variants") && flag_data.key?("defaultVariant")
            end

            # Selects the appropriate variant based on targeting rules
            # @param flag_data [Hash] The multi-variant flag data
            # @param context [OpenFeature::EvaluationContext, nil] Evaluation context for targeting
            # @return [Hash] The selected variant
            def select_variant(flag_data, context)
              variants = flag_data["variants"] || []
              default_variant_name = flag_data["defaultVariant"]

              # Find default variant
              default_variant = variants.find { |v| v["name"] == default_variant_name }

              # If no context or no targeting rules, return default variant
              context_attributes = get_context_attributes(context)
              return default_variant if context.nil? || context_attributes.nil? || context_attributes.empty?

              # Evaluate targeting rules
              selected_variant = evaluate_targeting_rules(flag_data, context)
              return selected_variant if selected_variant

              # Fall back to default variant
              default_variant
            end

            # Gets attributes from evaluation context
            # @param context [OpenFeature::EvaluationContext, nil] Evaluation context
            # @return [Hash, nil] Attributes hash or nil
            def get_context_attributes(context)
              return nil if context.nil?

              # Try different ways to access attributes
              if context.respond_to?(:attributes)
                context.attributes
              elsif context.respond_to?(:targeting_attributes)
                context.targeting_attributes
              elsif context.respond_to?(:fields)
                fields = context.fields
                # Try both string and symbol keys
                fields["attributes"] || fields[:attributes] if fields.is_a?(Hash)
              end
            end

            # Evaluates targeting rules to select a variant
            # @param flag_data [Hash] The multi-variant flag data
            # @param context [OpenFeature::EvaluationContext] Evaluation context
            # @return [Hash, nil] The selected variant or nil if no match
            def evaluate_targeting_rules(flag_data, context)
              targeting_rules = flag_data["targetingRules"] || []

              targeting_rules.each do |rule|
                next unless rule_matches?(rule, context)

                variant_name = rule["variant"]
                variant = find_variant_by_name(flag_data["variants"], variant_name)
                return variant if variant
              end

              nil
            end

            # Checks if a targeting rule matches the evaluation context
            # @param rule [Hash] The targeting rule to evaluate
            # @param context [OpenFeature::EvaluationContext] Evaluation context
            # @return [Boolean] True if the rule matches
            def rule_matches?(rule, context)
              conditions = rule["conditions"] || []

              conditions.all? do |condition|
                condition_matches?(condition, context)
              end
            end

            # Checks if a condition matches the evaluation context
            # @param condition [Hash] The condition to evaluate
            # @param context [OpenFeature::EvaluationContext] Evaluation context
            # @return [Boolean] True if the condition matches
            def condition_matches?(condition, context)
              attribute_key = condition["attribute"]
              operator = condition["operator"]
              value = condition["value"]

              context_attributes = get_context_attributes(context)
              context_value = context_attributes[attribute_key] if context_attributes
              return false if context_value.nil?

              evaluate_operator?(operator, context_value, value)
            end

            # Evaluates a single operator condition
            # @param operator [String] The operator to evaluate
            # @param context_value [Object] The context value
            # @param value [Object] The condition value
            # @return [Boolean] True if the condition matches
            def evaluate_operator?(operator, context_value, value)
              operator_method = OPERATOR_METHODS[operator]
              return false unless operator_method

              send(operator_method, context_value, value)
            end

            # Operator implementations
            def equals_operator?(context_value, value)
              context_value == value
            end

            def not_equals_operator?(context_value, value)
              context_value != value
            end

            def contains_operator?(context_value, value)
              context_value.to_s.include?(value.to_s)
            end

            def not_contains_operator?(context_value, value)
              !context_value.to_s.include?(value.to_s)
            end

            def starts_with_operator?(context_value, value)
              context_value.to_s.start_with?(value.to_s)
            end

            def ends_with_operator?(context_value, value)
              context_value.to_s.end_with?(value.to_s)
            end

            def greater_than_operator?(context_value, value)
              return false unless valid_float?(context_value) && valid_float?(value)

              Float(context_value) > Float(value)
            rescue ArgumentError, TypeError
              false
            end

            def greater_than_or_equal_operator?(context_value, value)
              return false unless valid_float?(context_value) && valid_float?(value)

              Float(context_value) >= Float(value)
            rescue ArgumentError, TypeError
              false
            end

            def less_than_operator?(context_value, value)
              return false unless valid_float?(context_value) && valid_float?(value)

              Float(context_value) < Float(value)
            rescue ArgumentError, TypeError
              false
            end

            def less_than_or_equal_operator?(context_value, value)
              return false unless valid_float?(context_value) && valid_float?(value)

              Float(context_value) <= Float(value)
            rescue ArgumentError, TypeError
              false
            end

            # Validates if a value can be converted to a float
            # @param value [Object] The value to validate
            # @return [Boolean] True if the value can be converted to float
            def valid_float?(value)
              Float(value)
              true
            rescue ArgumentError, TypeError
              false
            end

            # Finds a variant by name
            # @param variants [Array] Array of variants
            # @param variant_name [String] Name of the variant to find
            # @return [Hash, nil] The variant or nil if not found
            def find_variant_by_name(variants, variant_name)
              variants.find { |v| v["name"] == variant_name }
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

            # Determines the resolution reason for a multi-variant flag
            # @param flag_data [Hash] The multi-variant flag data
            # @param context [OpenFeature::EvaluationContext, nil] Evaluation context
            # @param selected_variant [Hash] The selected variant
            # @return [String] The resolution reason
            def determine_resolution_reason(flag_data, context, selected_variant)
              default_variant_name = flag_data["defaultVariant"]

              # If the selected variant is the default variant, it's DEFAULT
              return "DEFAULT" if selected_variant["name"] == default_variant_name

              # If no context or no targeting rules, it's DEFAULT
              context_attributes = get_context_attributes(context)
              return "DEFAULT" if context.nil? || context_attributes.nil? || context_attributes.empty?

              # Check if any targeting rule matches
              return "TARGETING_MATCH" if targeting_rule_matches?(flag_data, context, selected_variant)

              # If no targeting rule matches, it's DEFAULT
              "DEFAULT"
            end

            # Checks if any targeting rule matches the selected variant
            # @param flag_data [Hash] The multi-variant flag data
            # @param context [OpenFeature::EvaluationContext] Evaluation context
            # @param selected_variant [Hash] The selected variant
            # @return [Boolean] True if a targeting rule matches
            def targeting_rule_matches?(flag_data, context, selected_variant)
              targeting_rules = flag_data["targetingRules"] || []
              targeting_rules.any? do |rule|
                rule_matches?(rule, context) && rule["variant"] == selected_variant["name"]
              end
            end
          end
        end
      end
    end
  end
end
