# frozen_string_literal: true

require "minitest/autorun"
require "net/http"
require "json"
require "timeout"
require_relative "../lib/openfeature/provider/ruby/aws/appconfig"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          # Helper module for integration tests with AppConfig Agent
          module IntegrationTestHelper
            AGENT_ENDPOINT = "http://localhost:2772"
            TEST_APPLICATION = "test-integration-app"
            TEST_ENVIRONMENT = "test-integration-env"
            TEST_CONFIG_PROFILE = "test-integration-profile"

            # Test configuration data that should be available in AppConfig Agent
            TEST_CONFIGURATION_DATA = {
              "test-boolean-flag" => true,
              "test-string-flag" => "Hello from Agent",
              "test-number-flag" => 42,
              "test-object-flag" => "{\"theme\": \"dark\", \"language\": \"en\"}",
              "test-multi-variant-flag" => {
                "variants" => [
                  { "name" => "english", "value" => "Hello World" },
                  { "name" => "japanese", "value" => "こんにちは世界" },
                  { "name" => "spanish", "value" => "Hola Mundo" }
                ],
                "defaultVariant" => "english",
                "targetingRules" => [
                  {
                    "conditions" => [
                      { "attribute" => "language", "operator" => "equals", "value" => "ja" }
                    ],
                    "variant" => "japanese"
                  },
                  {
                    "conditions" => [
                      { "attribute" => "language", "operator" => "equals", "value" => "es" }
                    ],
                    "variant" => "spanish"
                  }
                ]
              },
              "test-complex-targeting-flag" => {
                "variants" => [
                  { "name" => "none", "value" => 0 },
                  { "name" => "standard", "value" => 10 },
                  { "name" => "premium", "value" => 25 },
                  { "name" => "vip", "value" => 50 }
                ],
                "defaultVariant" => "none",
                "targetingRules" => [
                  {
                    "conditions" => [
                      { "attribute" => "plan", "operator" => "equals", "value" => "premium" },
                      { "attribute" => "country", "operator" => "equals", "value" => "US" }
                    ],
                    "variant" => "premium"
                  },
                  {
                    "conditions" => [
                      { "attribute" => "plan", "operator" => "equals", "value" => "vip" }
                    ],
                    "variant" => "vip"
                  }
                ]
              }
            }.freeze

            def self.agent_running?
              uri = URI.parse("#{AGENT_ENDPOINT}/applications/#{TEST_APPLICATION}/" \
                              "environments/#{TEST_ENVIRONMENT}/configurations/#{TEST_CONFIG_PROFILE}")
              http = Net::HTTP.new(uri.host, uri.port)
              http.read_timeout = 5
              http.open_timeout = 5

              begin
                response = http.get(uri.path)
                response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPNotFound)
              rescue StandardError
                false
              end
            end

            def self.create_agent_provider
              Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
                application: TEST_APPLICATION,
                environment: TEST_ENVIRONMENT,
                configuration_profile: TEST_CONFIG_PROFILE,
                mode: :agent,
                agent_endpoint: AGENT_ENDPOINT
              )
            end

            def self.setup_test_configuration
              puts "Integration test setup: Ensure AppConfig Agent has test configuration"
              puts "Expected configuration keys: #{TEST_CONFIGURATION_DATA.keys.join(", ")}"
            end

            def self.cleanup_test_configuration
              puts "Integration test cleanup completed"
            end

            def self.skip_unless_agent_running
              return if agent_running?

              skip "AppConfig Agent is not running on #{AGENT_ENDPOINT}. " \
                   "Please start the agent for integration tests."
            end
          end
        end
      end
    end
  end
end
