#!/usr/bin/env ruby
# frozen_string_literal: true

# Integration test example for OpenFeature AWS AppConfig Provider with AppConfig Agent

require "bundler/setup"
require "open_feature/sdk"
require_relative "../lib/openfeature/provider/ruby/aws/appconfig"

# This example demonstrates how to run integration tests with AppConfig Agent
# Prerequisites:
# 1. AppConfig Agent must be running on http://localhost:2772
# 2. AWS AppConfig must have the following configuration:
#    - Application: test-integration-app
#    - Environment: test-integration-env
#    - Configuration Profile: test-integration-profile
#    - Configuration data (see test/integration_test_helper.rb for expected format)

puts "=== OpenFeature AWS AppConfig Provider Integration Test Example ==="
puts

# Check if AppConfig Agent is running
def agent_running?
  require "net/http"
  require "uri"

  uri = URI.parse("http://localhost:2772/applications/test-integration-app/" \
                  "environments/test-integration-env/configurations/test-integration-profile")
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = 5
  http.open_timeout = 5

  response = http.get(uri.path)
  response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPNotFound)
rescue StandardError
  false
end

unless agent_running?
  puts "❌ AppConfig Agent is not running on http://localhost:2772"
  puts "Please start the AppConfig Agent before running this example."
  puts
  puts "To start the agent:"
  puts "1. Install AppConfig Agent (follow AWS documentation)"
  puts "2. Configure AWS credentials"
  puts "3. Start the agent"
  puts "4. Ensure test configuration is deployed to AWS AppConfig"
  exit 1
end

puts "✅ AppConfig Agent is running"
puts

# Create the AWS AppConfig provider in Agent mode
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "test-integration-app",
  environment: "test-integration-env",
  configuration_profile: "test-integration-profile",
  mode: :agent,
  agent_endpoint: "http://localhost:2772"
)

puts "=== Basic Feature Flag Resolution ==="

# Test boolean flag
begin
  result = provider.resolve_boolean_value(flag_key: "test-boolean-flag")
  puts "✅ Boolean flag: #{result.resolution_details.value} (reason: #{result.resolution_details.reason})"
rescue StandardError => e
  puts "❌ Boolean flag error: #{e.message}"
end

# Test string flag
begin
  result = provider.resolve_string_value(flag_key: "test-string-flag")
  puts "✅ String flag: #{result.resolution_details.value} (reason: #{result.resolution_details.reason})"
rescue StandardError => e
  puts "❌ String flag error: #{e.message}"
end

# Test number flag
begin
  result = provider.resolve_number_value(flag_key: "test-number-flag")
  puts "✅ Number flag: #{result.resolution_details.value} (reason: #{result.resolution_details.reason})"
rescue StandardError => e
  puts "❌ Number flag error: #{e.message}"
end

# Test object flag
begin
  result = provider.resolve_object_value(flag_key: "test-object-flag")
  puts "✅ Object flag: #{result.resolution_details.value} (reason: #{result.resolution_details.reason})"
rescue StandardError => e
  puts "❌ Object flag error: #{e.message}"
end

puts
puts "=== Multi-Variant Feature Flags ==="

# Test multi-variant flag with different contexts
contexts = [
  {
    name: "English user",
    context: OpenFeature::SDK::EvaluationContext.new(
      targeting_key: "user-en",
      attributes: { "language" => "en" }
    )
  },
  {
    name: "Japanese user",
    context: OpenFeature::SDK::EvaluationContext.new(
      targeting_key: "user-ja",
      attributes: { "language" => "ja" }
    )
  },
  {
    name: "Spanish user",
    context: OpenFeature::SDK::EvaluationContext.new(
      targeting_key: "user-es",
      attributes: { "language" => "es" }
    )
  },
  {
    name: "No context",
    context: nil
  }
]

contexts.each do |test_case|
  result = provider.resolve_string_value(
    flag_key: "test-multi-variant-flag",
    context: test_case[:context]
  )
  puts "✅ #{test_case[:name]}: #{result.resolution_details.value} (reason: #{result.resolution_details.reason})"
rescue StandardError => e
  puts "❌ #{test_case[:name]} error: #{e.message}"
end

puts
puts "=== Complex Targeting ==="

# Test complex targeting with multiple conditions
complex_contexts = [
  {
    name: "Premium US user",
    context: OpenFeature::SDK::EvaluationContext.new(
      targeting_key: "premium-us",
      attributes: {
        "plan" => "premium",
        "country" => "US",
        "user_type" => "admin"
      }
    )
  },
  {
    name: "VIP user",
    context: OpenFeature::SDK::EvaluationContext.new(
      targeting_key: "vip-user",
      attributes: {
        "plan" => "vip",
        "country" => "JP"
      }
    )
  },
  {
    name: "Regular user",
    context: OpenFeature::SDK::EvaluationContext.new(
      targeting_key: "regular-user",
      attributes: {
        "plan" => "regular",
        "country" => "US"
      }
    )
  }
]

complex_contexts.each do |test_case|
  result = provider.resolve_number_value(
    flag_key: "test-complex-targeting-flag",
    context: test_case[:context]
  )
  puts "✅ #{test_case[:name]}: #{result.resolution_details.value}% (reason: #{result.resolution_details.reason})"
rescue StandardError => e
  puts "❌ #{test_case[:name]} error: #{e.message}"
end

puts
puts "=== Fetch Methods (with fallback) ==="

# Test fetch methods that provide fallback values
begin
  boolean_value = provider.fetch_boolean_value(
    flag_key: "test-boolean-flag",
    default_value: false
  )
  puts "✅ Fetch boolean: #{boolean_value}"
rescue StandardError => e
  puts "❌ Fetch boolean error: #{e.message}"
end

begin
  string_value = provider.fetch_string_value(
    flag_key: "test-string-flag",
    default_value: "Default"
  )
  puts "✅ Fetch string: #{string_value}"
rescue StandardError => e
  puts "❌ Fetch string error: #{e.message}"
end

begin
  number_value = provider.fetch_number_value(
    flag_key: "test-number-flag",
    default_value: 0
  )
  puts "✅ Fetch number: #{number_value}"
rescue StandardError => e
  puts "❌ Fetch number error: #{e.message}"
end

begin
  object_value = provider.fetch_object_value(
    flag_key: "test-object-flag",
    default_value: {}
  )
  puts "✅ Fetch object: #{object_value}"
rescue StandardError => e
  puts "❌ Fetch object error: #{e.message}"
end

puts
puts "=== Error Handling ==="

# Test error handling for non-existent flag
begin
  result = provider.resolve_boolean_value(flag_key: "non-existent-flag")
  puts "✅ Non-existent flag handled: #{result.resolution_details.value} (reason: #{result.resolution_details.reason})"
rescue StandardError => e
  puts "❌ Non-existent flag error: #{e.message}"
end

puts
puts "=== Integration Test Summary ==="
puts "This example demonstrates:"
puts "- Real HTTP communication with AppConfig Agent"
puts "- Actual configuration retrieval from AWS AppConfig"
puts "- Server-side targeting rule evaluation"
puts "- Error handling and fallback mechanisms"
puts "- All data type support (boolean, string, number, object)"
puts "- Multi-variant feature flags with complex targeting"
puts
puts "To run the actual integration tests:"
puts "bundle exec rake test:integration"
