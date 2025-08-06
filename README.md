# OpenFeature AWS AppConfig Provider for Ruby

A Ruby provider for OpenFeature that integrates with AWS AppConfig for feature flag management.

## Features

- ✅ Full OpenFeature specification compliance
- ✅ AWS AppConfig integration using the latest AppConfigData API
- ✅ Support for all data types (boolean, string, number, object) - Note: AWS AppConfig natively supports boolean, string, number, and arrays. Object types are handled by storing JSON strings and parsing them client-side.
- ✅ **Multi-variant feature flags with targeting rules**
- ✅ **Advanced targeting operators (equals, contains, starts_with, etc.)**
- ✅ **Complex targeting conditions with multiple attributes**
- ✅ **Session management for efficient configuration retrieval**
- ✅ Comprehensive error handling
- ✅ Type conversion and validation
- ✅ Unit tests with mocking

## Installation

Add this line to your application's Gemfile:

```ruby
gem "openfeature-provider-ruby-aws-appconfig"
```

And then execute:

```bash
bundle install
```

## Operation Modes

This provider supports two operation modes for AWS AppConfig integration:

### Direct SDK Mode (Default)
Uses the latest AWS AppConfigData API directly. This mode provides:

- **Free API calls**: No charges for configuration retrieval
- **Session management**: Efficient configuration retrieval with session tokens
- **Better performance**: Optimized for frequent configuration access
- **Future-proof**: Uses the recommended AWS API
- **Client-side targeting**: Custom targeting logic evaluation

The provider automatically handles:
- Session creation and management
- Token refresh when sessions expire
- Error handling and retry logic

### Agent Mode
Uses AWS AppConfig Agent for configuration retrieval. This mode provides:

- **Server-side targeting**: More secure targeting rule evaluation
- **Local endpoint**: Efficient local HTTP API access
- **Simplified authentication**: Agent handles AWS credentials
- **Network efficiency**: Reduced AWS API calls

### Mode Selection

```ruby
# Direct SDK mode (default)
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  mode: :direct_sdk  # or omit for default
)

# Agent mode
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  mode: :agent,
  agent_endpoint: "http://localhost:2772"  # default endpoint
)
```

## Usage

### Basic Usage

```ruby
require "open_feature/sdk"
require "openfeature/provider/ruby/aws/appconfig"

# Initialize the OpenFeature client
client = OpenFeature::SDK::Client.new

# Create and register the AWS AppConfig provider
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1"
)

client.set_provider(provider)

# Resolve feature flags
is_feature_enabled = client.get_boolean_value("new-feature", false)
welcome_message = client.get_string_value("welcome-message", "Welcome!")
max_retries = client.get_number_value("max-retries", 3)
user_config = client.get_object_value("user-config", {})
```

### Multi-Variant Feature Flags

The provider supports AWS AppConfig's multi-variant feature flags with targeting rules:

```ruby
# Create evaluation context with user attributes
context = OpenFeature::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: {
    "language" => "ja",
    "country" => "JP",
    "plan" => "premium",
    "user_type" => "admin"
  }
)

# Resolve multi-variant flags with context
personalized_message = client.get_string_value("welcome-message", "Hello", context)
discount_percentage = client.get_number_value("discount-percentage", 0, context)
user_theme = client.get_object_value("user-theme", {}, context)
```

### With Evaluation Context

```ruby
# Create evaluation context
context = OpenFeature::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: {
    "country" => "US",
    "plan" => "premium"
  }
)

# Resolve flags with context
personalized_feature = client.get_boolean_value("personalized-feature", false, context)
```

### Direct Provider Usage

```ruby
# Create provider directly
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1"
)

# Resolve flags directly
result = provider.resolve_boolean_value("feature-flag")
puts "Value: #{result.value}"
puts "Variant: #{result.variant}"
puts "Reason: #{result.reason}"
```

## Configuration

### Required Parameters

- `application`: The AWS AppConfig application name
- `environment`: The AWS AppConfig environment name
- `configuration_profile`: The AWS AppConfig configuration profile name

### Optional Parameters

- `region`: AWS region (default: "us-east-1")
- `credentials`: AWS credentials (default: uses AWS SDK default credential chain)
- `endpoint_url`: Custom endpoint URL (useful for testing with custom endpoints)

## Development

### Prerequisites

- Ruby 3.1 or higher
- AWS CLI (optional, for AWS AppConfig testing)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd openfeature-provider-ruby-aws-appconfig
```

2. Install dependencies:
```bash
bundle install
```



### Running Tests

#### Unit Tests (with mocking)
```bash
bundle exec rake test:unit
```

#### All Tests
```bash
bundle exec rake test
```

### Test Structure

- **Unit Tests**: Located in `test/openfeature/provider/ruby/aws/`
  - Use mocking for AWS SDK calls
  - Fast execution
  - No external dependencies

## AWS AppConfig Configuration

### Simple Feature Flags

```json
{
  "feature-flag": true,
  "welcome-message": "Hello World!",
  "max-retries": 5,
  "user-config": "{\"theme\": \"dark\", \"language\": \"en\"}"
}
```

**Note**: AWS AppConfig natively supports boolean, string, number, and arrays. For object types, store them as JSON strings in AWS AppConfig. The provider will automatically parse JSON strings into objects when using `get_object_value()`.

### Multi-Variant Feature Flags

The provider supports AWS AppConfig's multi-variant feature flag format:

```json
{
  "welcome-message": {
    "variants": [
      { "name": "english", "value": "Hello World" },
      { "name": "japanese", "value": "こんにちは世界" },
      { "name": "spanish", "value": "Hola Mundo" }
    ],
    "defaultVariant": "english",
    "targetingRules": [
      {
        "conditions": [
          { "attribute": "language", "operator": "equals", "value": "ja" }
        ],
        "variant": "japanese"
      },
      {
        "conditions": [
          { "attribute": "language", "operator": "equals", "value": "es" }
        ],
        "variant": "spanish"
      }
    ]
  },
  "discount-percentage": {
    "variants": [
      { "name": "none", "value": 0 },
      { "name": "standard", "value": 10 },
      { "name": "premium", "value": 20 },
      { "name": "vip", "value": 30 }
    ],
    "defaultVariant": "none",
    "targetingRules": [
      {
        "conditions": [
          { "attribute": "plan", "operator": "equals", "value": "premium" },
          { "attribute": "country", "operator": "equals", "value": "US" }
        ],
        "variant": "premium"
      },
      {
        "conditions": [
          { "attribute": "plan", "operator": "equals", "value": "vip" }
        ],
        "variant": "vip"
      }
    ]
  }
}
```

### Supported Targeting Operators

The provider supports the following targeting operators:

- `equals`: Exact match
- `not_equals`: Not equal
- `contains`: String contains
- `not_contains`: String does not contain
- `starts_with`: String starts with
- `ends_with`: String ends with
- `greater_than`: Numeric comparison
- `greater_than_or_equal`: Numeric comparison
- `less_than`: Numeric comparison
- `less_than_or_equal`: Numeric comparison

### Multi-Variant Flag Structure

Each multi-variant flag should have:

1. **`variants`**: Array of variant objects with `name` and `value` properties
2. **`defaultVariant`**: Name of the default variant to use when no targeting rules match
3. **`targetingRules`** (optional): Array of targeting rules

Each targeting rule contains:
- **`conditions`**: Array of conditions (all must match for the rule to apply)
- **`variant`**: Name of the variant to return when conditions match

Each condition contains:
- **`attribute`**: The attribute name from the evaluation context
- **`operator`**: The comparison operator
- **`value`**: The value to compare against

### AWS AppConfig Setup

1. Create an application in AWS AppConfig
2. Create an environment
3. Create a configuration profile
4. Create a configuration version with your JSON (simple or multi-variant)
5. Deploy the configuration

## Error Handling

The provider handles various error scenarios:

- **Configuration Not Found**: Returns error with appropriate message
- **Throttling**: Handles AWS throttling exceptions
- **Parse Errors**: Handles JSON parsing errors
- **Type Conversion**: Graceful handling of type mismatches
- **Targeting Rule Errors**: Falls back to default variant when targeting fails

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for your changes
5. Run the test suite
6. Submit a pull request

## License

This gem is available as open source under the terms of the MIT License.

## Support

For issues and questions:

1. Check the [OpenFeature specification](https://openfeature.dev/specification/)
2. Review AWS AppConfig documentation
3. Open an issue in this repository
