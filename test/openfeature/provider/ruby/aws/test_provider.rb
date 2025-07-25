# frozen_string_literal: true

require "test_helper"
require "open_feature/sdk"
require "aws-sdk-appconfig"
require "openfeature/provider/ruby/aws/appconfig"

class Openfeature::Provider::Ruby::Aws::Appconfig::ProviderTest < Minitest::Test
  def setup
    @mock_client = Minitest::Mock.new
    # Create provider with mocked client
    @provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile",
      client: @mock_client
    )
  end

  def test_initialize_with_required_parameters
    provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    )

    assert_equal "test-app", provider.application
    assert_equal "test-env", provider.environment
    assert_equal "test-profile", provider.configuration_profile
  end

  def test_initialize_missing_application
    assert_raises(ArgumentError) do
      Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
        environment: "test-env",
        configuration_profile: "test-profile"
      )
    end
  end

  def test_initialize_missing_environment
    assert_raises(ArgumentError) do
      Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
        application: "test-app",
        configuration_profile: "test-profile"
      )
    end
  end

  def test_initialize_missing_configuration_profile
    assert_raises(ArgumentError) do
      Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
        application: "test-app",
        environment: "test-env"
      )
    end
  end

  def test_resolve_boolean_value_success
    mock_response = mock_configuration_response('{"feature-flag": true}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_boolean_value("feature-flag")
    assert_equal true, result.value
    assert_equal "default", result.variant
    assert_equal "DEFAULT", result.reason

    @mock_client.verify
  end

  def test_resolve_string_value_success
    mock_response = mock_configuration_response('{"welcome-message": "Hello World"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_string_value("welcome-message")
    assert_equal "Hello World", result.value
    assert_equal "default", result.variant
    assert_equal "DEFAULT", result.reason

    @mock_client.verify
  end

  def test_resolve_number_value_success
    mock_response = mock_configuration_response('{"max-retries": 5}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_number_value("max-retries")
    assert_equal 5, result.value
    assert_equal "default", result.variant
    assert_equal "DEFAULT", result.reason

    @mock_client.verify
  end

  def test_resolve_object_value_success
    mock_response = mock_configuration_response('{"user-config": {"theme": "dark", "language": "en"}}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_object_value("user-config")
    expected = { "theme" => "dark", "language" => "en" }
    assert_equal expected, result.value
    assert_equal "default", result.variant
    assert_equal "DEFAULT", result.reason

    @mock_client.verify
  end

  def test_resolve_boolean_value_with_fallback
    mock_response = mock_configuration_response('{"feature-flag": "invalid"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_boolean_value("feature-flag")
    assert_equal false, result.value

    @mock_client.verify
  end

  def test_resolve_boolean_value_string_true
    mock_response = mock_configuration_response('{"feature-flag": "true"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_boolean_value("feature-flag")
    assert_equal true, result.value

    @mock_client.verify
  end

  def test_resolve_boolean_value_string_false
    mock_response = mock_configuration_response('{"feature-flag": "false"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_boolean_value("feature-flag")
    assert_equal false, result.value

    @mock_client.verify
  end

  def test_resolve_boolean_value_number
    mock_response = mock_configuration_response('{"feature-flag": 1}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_boolean_value("feature-flag")
    assert_equal true, result.value

    @mock_client.verify
  end

  def test_resolve_boolean_value_zero
    mock_response = mock_configuration_response('{"feature-flag": 0}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_boolean_value("feature-flag")
    assert_equal false, result.value

    @mock_client.verify
  end

  def test_resolve_number_value_string
    mock_response = mock_configuration_response('{"max-retries": "10"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_number_value("max-retries")
    assert_equal 10.0, result.value

    @mock_client.verify
  end

  def test_resolve_number_value_invalid_string
    mock_response = mock_configuration_response('{"max-retries": "invalid"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_number_value("max-retries")
    assert_equal 0, result.value

    @mock_client.verify
  end

  def test_resolve_object_value_string_json
    mock_response = mock_configuration_response('{"user-config": "{\\"theme\\": \\"dark\\"}"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_object_value("user-config")
    expected = { "theme" => "dark" }
    assert_equal expected, result.value

    @mock_client.verify
  end

  def test_resolve_object_value_invalid_json
    mock_response = mock_configuration_response('{"user-config": "invalid json"}')
    @mock_client.expect :get_configuration, mock_response, [{
      application: "test-app",
      environment: "test-env",
      configuration_profile: "test-profile"
    }]

    result = @provider.resolve_object_value("user-config")
    assert_equal({}, result.value)

    @mock_client.verify
  end

  private

  def mock_configuration_response(content)
    mock_response = Minitest::Mock.new
    mock_content = Minitest::Mock.new
    mock_content.expect :read, content
    mock_response.expect :content, mock_content
    mock_response
  end
end
