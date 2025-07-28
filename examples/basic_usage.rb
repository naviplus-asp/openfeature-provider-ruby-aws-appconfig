#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic usage example for OpenFeature AWS AppConfig Provider

require "bundler/setup"
require "open_feature/sdk"
require_relative "../lib/openfeature/provider/ruby/aws/appconfig"

# Create a mock AWS AppConfig client for demonstration
mock_client = Object.new
mock_client.instance_variable_set(:@config_data, {
                                    "new-feature" => true,
                                    "welcome-message" => "Hello from AWS AppConfig!",
                                    "max-retries" => 5,
                                    "user-config" => { "theme" => "dark", "language" => "en" },
                                    "personalized-feature" => true
                                  })

def mock_client.get_configuration(*)
  response = Object.new
  content = Object.new

  def content.read
    JSON.generate(@config_data)
  end

  attr_reader :content

  response.instance_variable_set(:@content, content)
  content.instance_variable_set(:@config_data, @config_data)
  response
end

# Create the AWS AppConfig provider with mock client
provider = Openfeature::Provider::Ruby::Aws::Appconfig.create_provider(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1",
  client: mock_client
)

puts "=== OpenFeature AWS AppConfig Provider Demo ==="
puts

# Example: Resolve a boolean flag using provider directly
begin
  is_feature_enabled = provider.fetch_boolean_value(flag_key: "new-feature", default_value: false)
  puts "✅ New feature enabled: #{is_feature_enabled}"
rescue StandardError => e
  puts "❌ Error resolving boolean flag: #{e.message}"
end

# Example: Resolve a string flag using provider directly
begin
  welcome_message = provider.fetch_string_value(flag_key: "welcome-message", default_value: "Welcome!")
  puts "✅ Welcome message: #{welcome_message}"
rescue StandardError => e
  puts "❌ Error resolving string flag: #{e.message}"
end

# Example: Resolve a number flag using provider directly
begin
  max_retries = provider.fetch_number_value(flag_key: "max-retries", default_value: 3)
  puts "✅ Max retries: #{max_retries}"
rescue StandardError => e
  puts "❌ Error resolving number flag: #{e.message}"
end

# Example: Resolve an object flag using provider directly
begin
  user_config = provider.fetch_object_value(flag_key: "user-config", default_value: {})
  puts "✅ User config: #{user_config}"
rescue StandardError => e
  puts "❌ Error resolving object flag: #{e.message}"
end

# Example: Using evaluation context with provider directly
context = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: {
    "country" => "US",
    "plan" => "premium"
  }
)

begin
  personalized_feature = provider.fetch_boolean_value(
    flag_key: "personalized-feature",
    default_value: false,
    evaluation_context: context
  )
  puts "✅ Personalized feature enabled: #{personalized_feature}"
rescue StandardError => e
  puts "❌ Error resolving personalized flag: #{e.message}"
end

puts
puts "=== Demo Complete ==="
puts
puts "Note: This example uses the provider directly due to a known issue"
puts "with OpenFeature SDK 0.4.0's value forwarding mechanism."
puts "In production, you would typically use the OpenFeature client."
