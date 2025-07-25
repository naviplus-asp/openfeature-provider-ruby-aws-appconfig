#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic usage example for OpenFeature AWS AppConfig Provider

require "bundler/setup"
require "open_feature/sdk"
require_relative "../lib/openfeature/provider/ruby/aws/appconfig"

# Initialize the OpenFeature client
client = OpenFeature::Client.new

# Create and register the AWS AppConfig provider
provider = Openfeature::Provider::Ruby::Aws::Appconfig.create_provider(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1"
)

client.set_provider(provider)

# Example: Resolve a boolean flag
begin
  is_feature_enabled = client.get_boolean_value("new-feature", false)
  puts "New feature enabled: #{is_feature_enabled}"
rescue StandardError => e
  puts "Error resolving boolean flag: #{e.message}"
end

# Example: Resolve a string flag
begin
  welcome_message = client.get_string_value("welcome-message", "Welcome!")
  puts "Welcome message: #{welcome_message}"
rescue StandardError => e
  puts "Error resolving string flag: #{e.message}"
end

# Example: Resolve a number flag
begin
  max_retries = client.get_number_value("max-retries", 3)
  puts "Max retries: #{max_retries}"
rescue StandardError => e
  puts "Error resolving number flag: #{e.message}"
end

# Example: Resolve an object flag
begin
  user_config = client.get_object_value("user-config", {})
  puts "User config: #{user_config}"
rescue StandardError => e
  puts "Error resolving object flag: #{e.message}"
end

# Example: Using evaluation context
context = OpenFeature::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: {
    "country" => "US",
    "plan" => "premium"
  }
)

begin
  personalized_feature = client.get_boolean_value("personalized-feature", false, context)
  puts "Personalized feature enabled: #{personalized_feature}"
rescue StandardError => e
  puts "Error resolving personalized flag: #{e.message}"
end
