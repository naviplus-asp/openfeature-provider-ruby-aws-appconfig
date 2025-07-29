#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic usage example for OpenFeature AWS AppConfig Provider

require "bundler/setup"
require "open_feature/sdk"
require_relative "../lib/openfeature/provider/ruby/aws/appconfig"

# Create a mock AWS AppConfig client for demonstration
mock_client = Object.new

# Configuration data including multi-variant flags
config_data = {
  "new-feature" => true,
  "welcome-message" => "Hello from AWS AppConfig!",
  "max-retries" => 5,
  "user-config" => { "theme" => "dark", "language" => "en" },
  "personalized-feature" => true,

  # Multi-variant flags
  "multi-welcome-message" => {
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

  "discount-percentage" => {
    "variants" => [
      { "name" => "none", "value" => 0 },
      { "name" => "standard", "value" => 10 },
      { "name" => "premium", "value" => 20 },
      { "name" => "vip", "value" => 30 }
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
      },
      {
        "conditions" => [
          { "attribute" => "plan", "operator" => "equals", "value" => "standard" }
        ],
        "variant" => "standard"
      }
    ]
  },

  "user-theme" => {
    "variants" => [
      { "name" => "light", "value" => { "theme" => "light", "accent" => "blue" } },
      { "name" => "dark", "value" => { "theme" => "dark", "accent" => "green" } },
      { "name" => "custom", "value" => { "theme" => "custom", "accent" => "purple" } }
    ],
    "defaultVariant" => "light",
    "targetingRules" => [
      {
        "conditions" => [
          { "attribute" => "preference", "operator" => "contains", "value" => "dark" }
        ],
        "variant" => "dark"
      },
      {
        "conditions" => [
          { "attribute" => "user_type", "operator" => "equals", "value" => "admin" }
        ],
        "variant" => "custom"
      }
    ]
  }
}

mock_client.instance_variable_set(:@config_data, config_data)

def mock_client.get_configuration(*)
  # モックレスポンスを作成
  response = Object.new
  content = Object.new

  # content.readメソッドを定義
  def content.read
    JSON.generate(@config_data)
  end

  # response.contentメソッドを定義
  response.define_singleton_method(:content) { @content }

  response.instance_variable_set(:@content, content)
  content.instance_variable_set(:@config_data, @config_data)
  response
end

# Create the AWS AppConfig provider with mock client
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1",
  client: mock_client
)

puts "=== OpenFeature AWS AppConfig Provider Demo ==="
puts

# Basic feature flags
puts "=== Basic Feature Flags ==="
begin
  is_feature_enabled = provider.fetch_boolean_value(flag_key: "new-feature", default_value: false)
  puts "✅ New feature enabled: #{is_feature_enabled}"
rescue StandardError => e
  puts "❌ Error resolving boolean flag: #{e.message}"
end

begin
  welcome_message = provider.fetch_string_value(flag_key: "welcome-message", default_value: "Welcome!")
  puts "✅ Welcome message: #{welcome_message}"
rescue StandardError => e
  puts "❌ Error resolving string flag: #{e.message}"
end

begin
  max_retries = provider.fetch_number_value(flag_key: "max-retries", default_value: 3)
  puts "✅ Max retries: #{max_retries}"
rescue StandardError => e
  puts "❌ Error resolving number flag: #{e.message}"
end

begin
  user_config = provider.fetch_object_value(flag_key: "user-config", default_value: {})
  puts "✅ User config: #{user_config}"
rescue StandardError => e
  puts "❌ Error resolving object flag: #{e.message}"
end

# Multi-variant feature flags
puts "\n=== Multi-Variant Feature Flags ==="

# Example 1: Language-based welcome message
puts "\n--- Language-based Welcome Message ---"
context_english = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: { "language" => "en" }
)

context_japanese = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-456",
  attributes: { "language" => "ja" }
)

context_spanish = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-789",
  attributes: { "language" => "es" }
)

begin
  welcome_en = provider.fetch_string_value(flag_key: "multi-welcome-message", default_value: "Hello",
                                           evaluation_context: context_english)
  welcome_ja = provider.fetch_string_value(flag_key: "multi-welcome-message", default_value: "Hello",
                                           evaluation_context: context_japanese)
  welcome_es = provider.fetch_string_value(flag_key: "multi-welcome-message", default_value: "Hello",
                                           evaluation_context: context_spanish)

  puts "✅ English welcome: #{welcome_en}"
  puts "✅ Japanese welcome: #{welcome_ja}"
  puts "✅ Spanish welcome: #{welcome_es}"
rescue StandardError => e
  puts "❌ Error resolving multi-variant welcome message: #{e.message}"
end

# Example 2: User plan-based discount
puts "\n--- Plan-based Discount ---"
context_premium_us = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-premium-1",
  attributes: { "plan" => "premium", "country" => "US" }
)

context_vip = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-vip-1",
  attributes: { "plan" => "vip" }
)

context_regular = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-regular-1",
  attributes: { "plan" => "regular" }
)

begin
  discount_premium = provider.fetch_number_value(flag_key: "discount-percentage", default_value: 0,
                                                 evaluation_context: context_premium_us)
  discount_vip = provider.fetch_number_value(flag_key: "discount-percentage", default_value: 0,
                                             evaluation_context: context_vip)
  discount_regular = provider.fetch_number_value(flag_key: "discount-percentage", default_value: 0,
                                                 evaluation_context: context_regular)

  puts "✅ Premium US discount: #{discount_premium}%"
  puts "✅ VIP discount: #{discount_vip}%"
  puts "✅ Regular discount: #{discount_regular}%"
rescue StandardError => e
  puts "❌ Error resolving discount percentage: #{e.message}"
end

# Example 3: Theme-based user interface
puts "\n--- Theme-based UI ---"
context_dark_preference = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-dark-1",
  attributes: { "preference" => "dark_mode" }
)

context_admin = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "admin-1",
  attributes: { "user_type" => "admin" }
)

context_regular_user = OpenFeature::SDK::EvaluationContext.new(
  targeting_key: "user-regular-2",
  attributes: { "user_type" => "regular" }
)

begin
  theme_dark = provider.fetch_object_value(flag_key: "user-theme", default_value: {},
                                           evaluation_context: context_dark_preference)
  theme_admin = provider.fetch_object_value(flag_key: "user-theme", default_value: {},
                                            evaluation_context: context_admin)
  theme_regular = provider.fetch_object_value(flag_key: "user-theme", default_value: {},
                                              evaluation_context: context_regular_user)

  puts "✅ Dark preference theme: #{theme_dark}"
  puts "✅ Admin theme: #{theme_admin}"
  puts "✅ Regular user theme: #{theme_regular}"
rescue StandardError => e
  puts "❌ Error resolving user theme: #{e.message}"
end

# Example 4: Fallback to default when no context provided
puts "\n--- Fallback to Default ---"
begin
  # No context provided - should use default variant
  default_result = provider.fetch_boolean_value(flag_key: "new-feature", default_value: false)
  puts "✅ Default result (no context): #{default_result}"
rescue StandardError => e
  puts "❌ Error resolving default flag: #{e.message}"
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
puts
puts "Multi-variant flags support:"
puts "- Multiple variants with different values"
puts "- Targeting rules based on user attributes"
puts "- Fallback to default variant when no rules match"
puts "- Support for complex targeting conditions"
