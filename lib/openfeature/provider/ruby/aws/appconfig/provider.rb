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
          # Supports both simple flags and multi-variant flags
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

              # Add endpoint URL for testing
              client_config[:endpoint] = config[:endpoint_url] if config[:endpoint_url]

              @client = config[:client] || ::Aws::AppConfig::Client.new(client_config)
            end

            # Resolves a boolean feature flag value from AWS AppConfig
            # @param flag_key [String] The feature flag key to resolve
            # @param context [OpenFeature::EvaluationContext, nil] Optional evaluation context for targeting
            # @return [OpenFeature::SDK::EvaluationDetails] Evaluation details containing the boolean value
            # @raise [StandardError] When configuration cannot be retrieved or parsed
            def resolve_boolean_value(flag_key:, context: nil)
              flag_data = get_configuration_value(flag_key, context)

              if multi_variant_flag?(flag_data)
                variant = select_variant(flag_data, context)
                if variant
                  value = convert_to_boolean(variant["value"])
                  # Determine if this is a targeting match or default
                  reason = determine_resolution_reason(flag_data, context, variant)
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: value,
                    variant: variant["name"] || "selected",
                    reason: reason
                  )
                else
                  # Fallback to default value if no variant found
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: false,
                    variant: "error",
                    reason: "ERROR",
                    error_code: "GENERAL",
                    error_message: "No matching variant found"
                  )
                end
              else
                # Simple flag
                value = convert_to_boolean(flag_data)
                resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                  value: value,
                  variant: "default",
                  reason: "DEFAULT"
                )
              end

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
            def resolve_string_value(flag_key:, context: nil)
              flag_data = get_configuration_value(flag_key, context)

              if multi_variant_flag?(flag_data)
                variant = select_variant(flag_data, context)
                if variant
                  value = convert_to_string(variant["value"])
                  # Determine if this is a targeting match or default
                  reason = determine_resolution_reason(flag_data, context, variant)
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: value,
                    variant: variant["name"] || "selected",
                    reason: reason
                  )
                else
                  # Fallback to default value if no variant found
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: "",
                    variant: "error",
                    reason: "ERROR",
                    error_code: "GENERAL",
                    error_message: "No matching variant found"
                  )
                end
              else
                # Simple flag
                value = convert_to_string(flag_data)
                resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                  value: value,
                  variant: "default",
                  reason: "DEFAULT"
                )
              end

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
            def resolve_number_value(flag_key:, context: nil)
              flag_data = get_configuration_value(flag_key, context)

              if multi_variant_flag?(flag_data)
                variant = select_variant(flag_data, context)
                if variant
                  value = convert_to_number(variant["value"])
                  # Determine if this is a targeting match or default
                  reason = determine_resolution_reason(flag_data, context, variant)
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: value,
                    variant: variant["name"] || "selected",
                    reason: reason
                  )
                else
                  # Fallback to default value if no variant found
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: 0,
                    variant: "error",
                    reason: "ERROR",
                    error_code: "GENERAL",
                    error_message: "No matching variant found"
                  )
                end
              else
                # Simple flag
                value = convert_to_number(flag_data)
                resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                  value: value,
                  variant: "default",
                  reason: "DEFAULT"
                )
              end

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
            def resolve_object_value(flag_key:, context: nil)
              flag_data = get_configuration_value(flag_key, context)

              if multi_variant_flag?(flag_data)
                variant = select_variant(flag_data, context)
                if variant
                  value = convert_to_object(variant["value"])
                  # Determine if this is a targeting match or default
                  reason = determine_resolution_reason(flag_data, context, variant)
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: value,
                    variant: variant["name"] || "selected",
                    reason: reason
                  )
                else
                  # Fallback to default value if no variant found
                  resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                    value: {},
                    variant: "error",
                    reason: "ERROR",
                    error_code: "GENERAL",
                    error_message: "No matching variant found"
                  )
                end
              else
                # Simple flag
                value = convert_to_object(flag_data)
                resolution_details = OpenFeature::SDK::Provider::ResolutionDetails.new(
                  value: value,
                  variant: "default",
                  reason: "DEFAULT"
                )
              end

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
              elsif context.instance_variable_defined?(:@fields)
                fields = context.instance_variable_get(:@fields)
                # Try both string and symbol keys
                fields["attributes"] || fields[:attributes] if fields.is_a?(Hash)
              else
                nil
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

              case operator
              when "equals"
                context_value == value
              when "not_equals"
                context_value != value
              when "contains"
                context_value.to_s.include?(value.to_s)
              when "not_contains"
                !context_value.to_s.include?(value.to_s)
              when "starts_with"
                context_value.to_s.start_with?(value.to_s)
              when "ends_with"
                context_value.to_s.end_with?(value.to_s)
              when "greater_than"
                context_value.to_f > value.to_f
              when "greater_than_or_equal"
                context_value.to_f >= value.to_f
              when "less_than"
                context_value.to_f < value.to_f
              when "less_than_or_equal"
                context_value.to_f <= value.to_f
              else
                false
              end
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
              targeting_rules = flag_data["targetingRules"] || []
              targeting_rules.each do |rule|
                return "TARGETING_MATCH" if rule_matches?(rule, context) && rule["variant"] == selected_variant["name"]
              end

              # If no targeting rule matches, it's DEFAULT
              "DEFAULT"
            end
          end
        end
      end
    end
  end
end
