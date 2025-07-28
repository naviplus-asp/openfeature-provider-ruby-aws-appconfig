# OpenFeature AWS AppConfig Provider for Ruby

A Ruby provider for OpenFeature that integrates with AWS AppConfig for feature flag management.

## Features

- ✅ Full OpenFeature specification compliance
- ✅ AWS AppConfig integration
- ✅ Support for all data types (boolean, string, number, object)
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

## Usage

### Basic Usage

```ruby
require "open_feature/sdk"
require "openfeature/provider/ruby/aws/appconfig"

# Initialize the OpenFeature client
client = OpenFeature::SDK::Client.new

# Create and register the AWS AppConfig provider
provider = Openfeature::Provider::Ruby::Aws::Appconfig.create_provider(
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

### Example Configuration JSON

```json
{
  "feature-flag": true,
  "welcome-message": "Hello World!",
  "max-retries": 5,
  "user-config": {
    "theme": "dark",
    "language": "en"
  }
}
```

### AWS AppConfig Setup

1. Create an application in AWS AppConfig
2. Create an environment
3. Create a configuration profile
4. Create a configuration version with your JSON
5. Deploy the configuration

## Error Handling

The provider handles various error scenarios:

- **Configuration Not Found**: Returns error with appropriate message
- **Throttling**: Handles AWS throttling exceptions
- **Parse Errors**: Handles JSON parsing errors
- **Type Conversion**: Graceful handling of type mismatches

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
