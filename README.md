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
- ✅ **Integration tests with AppConfig Agent**
- ✅ **Docker Compose setup for easy integration testing**
- ✅ **GitHub Actions CI with integration tests**

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
    "user_id" => "123",
    "country" => "US",
    "plan" => "premium"
  }
)

# Resolve feature flags with context
is_feature_enabled = client.get_boolean_value("new-feature", false, context)
```

## Testing

### Unit Tests (with mocking)
```bash
bundle exec rake test_unit
```

### Integration Tests (with AppConfig Agent)

#### Option 1: Using Docker Compose (Recommended)

We provide Docker Compose configurations for easy integration testing:

```bash
# Start integration test environment
./scripts/start-integration-tests.sh
```

This script will:
1. Check if Docker is running
2. Verify port availability
3. Let you choose between:
   - Real AppConfig Agent (requires AWS credentials)
   - Mock server (no AWS credentials required)
4. Start the appropriate service
5. Verify the service is responding

#### Option 2: Manual Setup

If you prefer to set up manually:

1. **Install and start AppConfig Agent**:
   ```bash
   # Install AppConfig Agent (follow AWS documentation)
   # Start the agent with your AWS credentials
   ```

2. **Configure test data in AWS AppConfig**:
   - Create application: `test-integration-app`
   - Create environment: `test-integration-env`
   - Create configuration profile: `test-integration-profile`
   - Deploy test configuration (see `test/integration_test_helper.rb` for expected data)

3. **Run integration tests**:
   ```bash
   bundle exec rake test_integration
   ```

#### Docker Compose Commands

```bash
# Start real AppConfig Agent (requires AWS credentials)
docker-compose up -d appconfig-agent

# Start mock server (no AWS credentials required)
docker-compose -f docker-compose.mock.yml up -d

# Stop services
docker-compose down
docker-compose -f docker-compose.mock.yml down

# View logs
docker-compose logs appconfig-agent
docker-compose -f docker-compose.mock.yml logs mock-appconfig-server
```

### All Tests
```bash
bundle exec rake test_all
```

### Test Structure

- **Unit Tests**: Located in `test/openfeature/provider/ruby/aws/`
  - Use mocking for AWS SDK calls
  - Fast execution
  - No external dependencies
  - Test both Direct SDK mode and Agent mode with mocks

- **Integration Tests**: Located in `test/openfeature/provider/ruby/aws/integration_test_provider.rb`
  - Use real AppConfig Agent or mock server
  - Test actual HTTP communication
  - Require AppConfig Agent to be running
  - Test real configuration retrieval and targeting

### Running Integration Tests

#### Using the Setup Script

```bash
# Start the integration test environment
./scripts/start-integration-tests.sh

# Choose your preferred mode when prompted
# Then run the tests
bundle exec rake test_integration
```

#### Manual Docker Setup

```bash
# For mock server (no AWS credentials needed)
docker-compose -f docker-compose.mock.yml up -d

# For real AppConfig Agent (requires AWS credentials)
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_REGION=us-east-1
docker-compose up -d appconfig-agent

# Run tests
bundle exec rake test_integration
```

## Continuous Integration

### GitHub Actions

This project includes comprehensive CI/CD with GitHub Actions:

- **RuboCop**: Code style and quality checks
- **Unit Tests**: Multi-Ruby version testing (3.1, 3.2, 3.3, 3.4)
- **Integration Tests**: Automated integration testing with mock AppConfig server

#### CI Workflow

The CI pipeline runs on every push and pull request:

1. **RuboCop**: Code style validation
2. **Unit Tests**: Tests across multiple Ruby versions
3. **Integration Tests**:
   - Sets up mock AppConfig server using Docker
   - Runs integration tests against the mock server
   - Verifies all functionality works with real HTTP communication

#### Viewing CI Results

- Go to the [Actions tab](https://github.com/naviplus-asp/openfeature-provider-ruby-aws-appconfig/actions) in the repository
- Each workflow run shows detailed results for all test stages
- Integration test logs include mock server setup and test execution details

#### Local CI Testing

To test the CI workflow locally:

```bash
# Run the same tests as CI
bundle exec rubocop
bundle exec rake test_unit
bundle exec rake test_integration
```

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
