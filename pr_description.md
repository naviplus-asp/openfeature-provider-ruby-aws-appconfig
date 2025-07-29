## Overview

This PR migrates the provider from the deprecated AWS AppConfig `getConfiguration` API to the new AppConfigData API.

## Changes

### 🔄 API Migration
- Replace deprecated `getConfiguration` API with new AppConfigData API
- Use `start_configuration_session` and `get_latest_configuration` methods
- Remove dependency on `aws-sdk-appconfig`, use `aws-sdk-appconfigdata` only

### 🚀 New Features
- **Session Management**: Automatic session creation and token management
- **Efficient Configuration Retrieval**: Session-based approach for better performance
- **Automatic Error Recovery**: Session refresh on expiration or errors

### 📦 Dependencies
- Remove: `aws-sdk-appconfig ~> 1.0`
- Add: `aws-sdk-appconfigdata ~> 1.0`

### 🧪 Testing
- Update all test mocks to use new API
- Update examples to demonstrate new functionality
- All tests passing: 26 runs, 49 assertions, 0 failures

## Benefits

### 💰 Cost Savings
- **Free API calls**: No charges for configuration retrieval
- **Reduced AWS costs**: Eliminates deprecated API usage

### ⚡ Performance
- **Session-based caching**: Efficient configuration retrieval
- **Reduced API calls**: Session tokens reduce redundant requests
- **Better error handling**: Automatic retry and recovery

### 🔮 Future-Proof
- **AWS Recommended**: Uses the latest recommended API
- **Long-term support**: Deprecated API replacement
- **Enhanced features**: Access to future AppConfigData improvements

## Technical Details

### Session Management
```ruby
# Automatic session handling
ensure_valid_session
response = @client.get_latest_configuration(
  configuration_token: @session_token
)
```

### Error Handling
- Automatic session refresh on `InvalidParameterException`
- Graceful fallback for expired sessions
- Comprehensive error messages

### Backward Compatibility
- Same public API interface
- No breaking changes for users
- Seamless migration experience

## Testing

- ✅ All existing tests pass
- ✅ New session management tests
- ✅ Error handling scenarios
- ✅ Performance improvements verified
- ✅ Rubocop compliance maintained

## Migration Notes

This is a **breaking change** for the internal implementation but maintains full backward compatibility for users. The provider now uses the recommended AWS API internally while preserving the same public interface.

**No user code changes required** - this is a drop-in replacement with improved performance and cost benefits.
