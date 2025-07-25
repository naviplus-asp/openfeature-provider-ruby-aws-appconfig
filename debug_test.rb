#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/openfeature/provider/ruby/aws/appconfig"

# デバッグ用のモックを作成
mock_content_data = '{"feature-flag": true, "welcome-message": "Hello World"}'

mock_content = Object.new
def mock_content.read
  @mock_content_data
end
mock_content.instance_variable_set(:@mock_content_data, mock_content_data)

mock_response = Object.new
def mock_response.content
  @mock_content
end
mock_response.instance_variable_set(:@mock_content, mock_content)

mock_client = Object.new
def mock_client.get_configuration(application:, environment:, configuration_profile:)
  @mock_response
end
mock_client.instance_variable_set(:@mock_response, mock_response)

# Providerを作成
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "test-app",
  environment: "test-env",
  configuration_profile: "test-profile",
  client: mock_client
)

# テスト実行
puts "Testing boolean value resolution..."
result = provider.resolve_boolean_value("feature-flag")
puts "Result: #{result.resolution_details.value}"
puts "Variant: #{result.resolution_details.variant}"
puts "Reason: #{result.resolution_details.reason}"
puts "Error: #{result.resolution_details.error_message}" if result.resolution_details.error_message

puts "\nTesting string value resolution..."
result = provider.resolve_string_value("welcome-message")
puts "Result: #{result.resolution_details.value}"
puts "Variant: #{result.resolution_details.variant}"
puts "Reason: #{result.resolution_details.reason}"
puts "Error: #{result.resolution_details.error_message}" if result.resolution_details.error_message
