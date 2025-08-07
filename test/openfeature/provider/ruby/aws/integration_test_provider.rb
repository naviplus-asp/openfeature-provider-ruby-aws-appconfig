# frozen_string_literal: true

require File.expand_path("../../../../test_helper", __dir__)
require File.expand_path("../../../../integration_test_helper", __dir__)
require "open_feature/sdk"
require "openfeature/provider/ruby/aws/appconfig"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class IntegrationTestProvider < Minitest::Test
            include IntegrationTestHelper

            def setup
              IntegrationTestHelper.skip_unless_agent_running
              IntegrationTestHelper.setup_test_configuration
            end

            def teardown
              IntegrationTestHelper.cleanup_test_configuration
            end

            def test_agent_mode_integration_boolean_flag
              provider = IntegrationTestHelper.create_agent_provider

              # Test boolean flag resolution
              result = provider.resolve_boolean_value(flag_key: "test-boolean-flag")

              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "test-boolean-flag", result.flag_key
              assert result.resolution_details.value
              # Agent mode returns DEFAULT for simple flags
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_agent_mode_integration_string_flag
              provider = IntegrationTestHelper.create_agent_provider

              # Test string flag resolution
              result = provider.resolve_string_value(flag_key: "test-string-flag")

              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "test-string-flag", result.flag_key
              assert_equal "Hello from Agent", result.resolution_details.value
              # Agent mode returns DEFAULT for simple flags
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_agent_mode_integration_number_flag
              provider = IntegrationTestHelper.create_agent_provider

              # Test number flag resolution
              result = provider.resolve_number_value(flag_key: "test-number-flag")

              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "test-number-flag", result.flag_key
              assert_equal 42, result.resolution_details.value
              # Agent mode returns DEFAULT for simple flags
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_agent_mode_integration_object_flag
              provider = IntegrationTestHelper.create_agent_provider

              # Test object flag resolution
              result = provider.resolve_object_value(flag_key: "test-object-flag")

              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "test-object-flag", result.flag_key
              expected_value = { "theme" => "dark", "language" => "en" }

              assert_equal expected_value, result.resolution_details.value
              # Agent mode returns DEFAULT for simple flags
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_agent_mode_integration_multi_variant_flag
              provider = IntegrationTestHelper.create_agent_provider
              context = create_test_context

              result = provider.resolve_string_value(
                flag_key: "test-multi-variant-flag",
                context: context
              )

              assert_multi_variant_result(result)
            end

            def create_test_context
              OpenFeature::SDK::EvaluationContext.new(
                targeting_key: "user-123",
                attributes: { "language" => "ja" }
              )
            end

            def assert_multi_variant_result(result)
              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "test-multi-variant-flag", result.flag_key
              # In Agent mode, the server handles targeting and returns a string representation
              # of the multi-variant configuration
              assert_kind_of String, result.resolution_details.value
              assert_includes result.resolution_details.value, "variants"
              assert_includes result.resolution_details.value, "defaultVariant"
              # Agent mode returns DEFAULT for multi-variant flags
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_agent_mode_integration_multi_variant_flag_default
              provider = IntegrationTestHelper.create_agent_provider

              # Test multi-variant flag without context (should use default)
              result = provider.resolve_string_value(flag_key: "test-multi-variant-flag")

              assert_multi_variant_default_result(result)
            end

            def assert_multi_variant_default_result(result)
              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "test-multi-variant-flag", result.flag_key
              # In Agent mode, we get a string representation of the multi-variant structure
              assert_kind_of String, result.resolution_details.value
              assert_includes result.resolution_details.value, "variants"
              assert_includes result.resolution_details.value, "defaultVariant"
              # Agent mode returns DEFAULT for multi-variant flags
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_agent_mode_integration_fetch_methods
              provider = IntegrationTestHelper.create_agent_provider

              # Test fetch methods with fallback
              boolean_value = provider.fetch_boolean_value(
                flag_key: "test-boolean-flag",
                default_value: false
              )

              assert boolean_value

              string_value = provider.fetch_string_value(
                flag_key: "test-string-flag",
                default_value: "Default"
              )

              assert_equal "Hello from Agent", string_value

              number_value = provider.fetch_number_value(
                flag_key: "test-number-flag",
                default_value: 0
              )

              assert_equal 42, number_value

              object_value = provider.fetch_object_value(
                flag_key: "test-object-flag",
                default_value: {}
              )
              expected_value = { "theme" => "dark", "language" => "en" }

              assert_equal expected_value, object_value
            end

            def test_agent_mode_integration_error_handling
              provider = IntegrationTestHelper.create_agent_provider

              # Test error handling for non-existent flag
              result = provider.resolve_boolean_value(flag_key: "non-existent-flag")

              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "non-existent-flag", result.flag_key
              refute result.resolution_details.value
              # Agent mode returns DEFAULT for non-existent flags (no error)
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_agent_mode_integration_complex_targeting
              provider = IntegrationTestHelper.create_agent_provider

              # Test complex targeting with multiple conditions
              context = OpenFeature::SDK::EvaluationContext.new(
                targeting_key: "premium-user",
                attributes: {
                  "plan" => "premium",
                  "country" => "US",
                  "user_type" => "admin"
                }
              )

              result = provider.resolve_number_value(
                flag_key: "test-complex-targeting-flag",
                context: context
              )

              assert_kind_of(OpenFeature::SDK::EvaluationDetails, result)
              assert_equal "test-complex-targeting-flag", result.flag_key
              # In Agent mode, the server handles targeting and returns the resolved value
              # For this test, it returns 0 (the default variant value)
              assert_equal 0, result.resolution_details.value
              # Agent mode returns DEFAULT for complex targeting flags
              assert_equal "DEFAULT", result.resolution_details.reason
            end
          end
        end
      end
    end
  end
end
