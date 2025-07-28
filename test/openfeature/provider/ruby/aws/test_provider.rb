# frozen_string_literal: true

require File.expand_path("../../../../test_helper", __dir__)
require "open_feature/sdk"
require "aws-sdk-appconfig"
require "openfeature/provider/ruby/aws/appconfig"

module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class ProviderTest < Minitest::Test
            def setup
              # シンプルなモッククライアントを作成
              @mock_client = create_mock_client
              @provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
                application: "test-app",
                environment: "test-env",
                configuration_profile: "test-profile",
                client: @mock_client
              )
            end

            def create_mock_client
              client = Object.new

              # デフォルトの設定データ
              client.instance_variable_set(:@config_data, {})

              # get_configurationメソッドを定義
              def client.get_configuration(**_kwargs)
                # モックレスポンスを作成
                response = Object.new
                content = Object.new

                # content.readメソッドを定義
                def content.read
                  JSON.generate(@config_data)
                end

                # response.contentメソッドを定義
                attr_reader :content

                response.instance_variable_set(:@content, content)
                content.instance_variable_set(:@config_data, @config_data)
                response
              end

              # 設定データを設定するメソッド
              attr_writer :config_data

              client
            end

            def mock_configuration_response(content)
              config_data = JSON.parse(content)
              @mock_client.config_data = config_data
            end

            def test_resolve_boolean_value_success
              mock_configuration_response('{"feature-flag": true}')
              result = @provider.resolve_boolean_value("feature-flag")

              assert result.resolution_details.value
              assert_equal "default", result.resolution_details.variant
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_resolve_string_value_success
              mock_configuration_response('{"welcome-message": "Hello World"}')
              result = @provider.resolve_string_value("welcome-message")

              assert_equal "Hello World", result.resolution_details.value
              assert_equal "default", result.resolution_details.variant
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_resolve_number_value_success
              mock_configuration_response('{"max-retries": 5}')
              result = @provider.resolve_number_value("max-retries")

              assert_equal 5, result.resolution_details.value
              assert_equal "default", result.resolution_details.variant
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_resolve_object_value_success
              mock_configuration_response('{"settings": {"theme": "dark"}}')
              result = @provider.resolve_object_value("settings")

              assert_equal({ "theme" => "dark" }, result.resolution_details.value)
              assert_equal "default", result.resolution_details.variant
              assert_equal "DEFAULT", result.resolution_details.reason
            end

            def test_resolve_boolean_value_with_fallback
              mock_configuration_response('{"feature-flag": "invalid"}')
              result = @provider.resolve_boolean_value("feature-flag")

              refute result.resolution_details.value
            end

            def test_resolve_boolean_value_string_true
              mock_configuration_response('{"feature-flag": "true"}')
              result = @provider.resolve_boolean_value("feature-flag")

              assert result.resolution_details.value
            end

            def test_resolve_boolean_value_string_false
              mock_configuration_response('{"feature-flag": "false"}')
              result = @provider.resolve_boolean_value("feature-flag")

              refute result.resolution_details.value
            end

            def test_resolve_boolean_value_number
              mock_configuration_response('{"feature-flag": 1}')
              result = @provider.resolve_boolean_value("feature-flag")

              assert result.resolution_details.value
            end

            def test_resolve_boolean_value_zero
              mock_configuration_response('{"feature-flag": 0}')
              result = @provider.resolve_boolean_value("feature-flag")

              refute result.resolution_details.value
            end

            def test_resolve_number_value_string
              mock_configuration_response('{"max-retries": "10"}')
              result = @provider.resolve_number_value("max-retries")

              assert_in_delta(10.0, result.resolution_details.value)
            end

            def test_resolve_number_value_invalid_string
              mock_configuration_response('{"max-retries": "invalid"}')
              result = @provider.resolve_number_value("max-retries")

              assert_equal 0, result.resolution_details.value
            end

            def test_resolve_object_value_string_json
              mock_configuration_response('{"user-config": "{\\"theme\\": \\"dark\\"}"}')
              result = @provider.resolve_object_value("user-config")
              expected = { "theme" => "dark" }

              assert_equal expected, result.resolution_details.value
            end

            def test_resolve_object_value_invalid_json
              mock_configuration_response('{"user-config": "invalid json"}')
              result = @provider.resolve_object_value("user-config")

              assert_empty(result.resolution_details.value)
            end
          end
        end
      end
    end
  end
end
