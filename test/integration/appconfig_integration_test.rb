# frozen_string_literal: true

require_relative "../test_helper"
require "open_feature/sdk"
require "openfeature/provider/ruby/aws/appconfig"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class IntegrationTest < Minitest::Test
            def setup
              @endpoint_url = ENV.fetch("AWS_ENDPOINT_URL", "http://localhost:4566")
              @helper = Openfeature::Provider::Ruby::Aws::Appconfig::LocalstackHelper.new(@endpoint_url)

              # Test configuration data
              @test_config = {
                "feature-flag" => true,
                "welcome-message" => "Hello from LocalStack!",
                "max-retries" => 5,
                "user-config" => {
                  "theme" => "dark",
                  "language" => "en"
                }
              }

              # Setup test resources
              @test_app_name = "test-app-#{SecureRandom.hex(4)}"
              @test_env_name = "test-env"
              @test_profile_name = "test-profile"

              @resources = @helper.setup_test_configuration(
                @test_app_name,
                @test_env_name,
                @test_profile_name,
                @test_config
              )

              # Create provider with LocalStack endpoint
              @provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
                application: @test_app_name,
                environment: @test_env_name,
                configuration_profile: @test_profile_name,
                region: "us-east-1",
                credentials: Aws::Credentials.new("test", "test"),
                endpoint_url: @endpoint_url
              )
            end

            def teardown
              # Cleanup test resources
              @helper.cleanup_test_resources(@resources[:application_id]) if @resources
            end

            def test_resolve_boolean_value_integration
              result = @provider.resolve_boolean_value("feature-flag")

              assert result.value
              assert_equal "default", result.variant
              assert_equal "DEFAULT", result.reason
              assert_nil result.error_code
              assert_nil result.error_message
            end

            def test_resolve_string_value_integration
              result = @provider.resolve_string_value("welcome-message")

              assert_equal "Hello from LocalStack!", result.value
              assert_equal "default", result.variant
              assert_equal "DEFAULT", result.reason
              assert_nil result.error_code
              assert_nil result.error_message
            end

            def test_resolve_number_value_integration
              result = @provider.resolve_number_value("max-retries")

              assert_equal 5, result.value
              assert_equal "default", result.variant
              assert_equal "DEFAULT", result.reason
              assert_nil result.error_code
              assert_nil result.error_message
            end

            def test_resolve_object_value_integration
              result = @provider.resolve_object_value("user-config")

              expected = { "theme" => "dark", "language" => "en" }

              assert_equal expected, result.value
              assert_equal "default", result.variant
              assert_equal "DEFAULT", result.reason
              assert_nil result.error_code
              assert_nil result.error_message
            end

            def test_resolve_nonexistent_flag
              result = @provider.resolve_boolean_value("nonexistent-flag")

              refute result.value
              assert_equal "error", result.variant
              assert_equal "ERROR", result.reason
              assert_equal "GENERAL", result.error_code
              assert_includes result.error_message, "Configuration not found"
            end

            def test_resolve_boolean_value_with_string_true
              # Update configuration with string "true"
              updated_config = @test_config.merge("string-true-flag" => "true")
              update_configuration(updated_config)

              result = @provider.resolve_boolean_value("string-true-flag")

              assert result.value
            end

            def test_resolve_boolean_value_with_string_false
              # Update configuration with string "false"
              updated_config = @test_config.merge("string-false-flag" => "false")
              update_configuration(updated_config)

              result = @provider.resolve_boolean_value("string-false-flag")

              refute result.value
            end

            def test_resolve_boolean_value_with_number
              # Update configuration with number
              updated_config = @test_config.merge("number-flag" => 1)
              update_configuration(updated_config)

              result = @provider.resolve_boolean_value("number-flag")

              assert result.value
            end

            def test_resolve_boolean_value_with_zero
              # Update configuration with zero
              updated_config = @test_config.merge("zero-flag" => 0)
              update_configuration(updated_config)

              result = @provider.resolve_boolean_value("zero-flag")

              refute result.value
            end

            def test_resolve_number_value_with_string
              # Update configuration with string number
              updated_config = @test_config.merge("string-number" => "10")
              update_configuration(updated_config)

              result = @provider.resolve_number_value("string-number")

              assert_in_delta(10.0, result.value)
            end

            def test_resolve_number_value_with_invalid_string
              # Update configuration with invalid string
              updated_config = @test_config.merge("invalid-number" => "invalid")
              update_configuration(updated_config)

              result = @provider.resolve_number_value("invalid-number")

              assert_equal 0, result.value
            end

            def test_resolve_object_value_with_string_json
              # Update configuration with JSON string
              updated_config = @test_config.merge("json-string" => '{"key": "value"}')
              update_configuration(updated_config)

              result = @provider.resolve_object_value("json-string")
              expected = { "key" => "value" }

              assert_equal expected, result.value
            end

            def test_resolve_object_value_with_invalid_json
              # Update configuration with invalid JSON
              updated_config = @test_config.merge("invalid-json" => "invalid json")
              update_configuration(updated_config)

              result = @provider.resolve_object_value("invalid-json")

              assert_empty(result.value)
            end

            def test_provider_with_openfeature_client
              # Create OpenFeature client
              client = OpenFeature::SDK::Client.new
              client.set_provider(@provider)

              # Test boolean flag
              result = client.get_boolean_value("feature-flag", false)

              assert result

              # Test string flag
              result = client.get_string_value("welcome-message", "default")

              assert_equal "Hello from LocalStack!", result

              # Test number flag
              result = client.get_number_value("max-retries", 0)

              assert_equal 5, result

              # Test object flag
              result = client.get_object_value("user-config", {})
              expected = { "theme" => "dark", "language" => "en" }

              assert_equal expected, result
            end

            def test_provider_with_evaluation_context
              # Create OpenFeature client
              client = OpenFeature::SDK::Client.new
              client.set_provider(@provider)

              # Create evaluation context
              context = OpenFeature::SDK::EvaluationContext.new(
                targeting_key: "user-123",
                attributes: {
                  "country" => "US",
                  "plan" => "premium"
                }
              )

              # Test with context (context is not used in this implementation, but should not cause errors)
              result = client.get_boolean_value("feature-flag", false, context)

              assert result
            end

            private

            def update_configuration(new_config)
              # Create new configuration version
              config_content = JSON.generate(new_config)
              version = @helper.create_hosted_configuration_version(
                @resources[:application_id],
                @test_profile_name,
                config_content
              )

              # Start new deployment
              deployment = @helper.start_deployment(
                @resources[:application_id],
                @test_env_name,
                @test_profile_name,
                "test-strategy"
              )

              # Wait for deployment to complete
              @helper.wait_for_deployment(
                @resources[:application_id],
                @test_env_name,
                deployment.deployment_number
              )

              # Update configuration version
              @resources[:configuration_version] = version.version_number
            end
          end
        end
      end
    end
  end
end
