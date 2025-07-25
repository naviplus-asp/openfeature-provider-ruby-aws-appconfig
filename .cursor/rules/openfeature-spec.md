# OpenFeature仕様準拠ルール

## OpenFeature仕様概要

### 1. 基本概念
- Feature Flag: 機能のオン/オフを制御するフラグ
- Provider: フラグの値を解決する実装
- Context: フラグ解決時のコンテキスト情報
- Evaluation: フラグの評価結果

### 2. 必須実装メソッド
```ruby
class AppconfigProvider
  # フラグの値を解決
  def resolve_boolean_value(flag_key, context = nil)
    # boolean型のフラグ値を解決
  end

  def resolve_string_value(flag_key, context = nil)
    # string型のフラグ値を解決
  end

  def resolve_number_value(flag_key, context = nil)
    # number型のフラグ値を解決
  end

  def resolve_object_value(flag_key, context = nil)
    # object型のフラグ値を解決
  end
end
```

## 評価結果の構造

### 1. 成功時の評価結果
```ruby
class EvaluationDetails
  attr_reader :value, :variant, :reason, :metadata

  def initialize(value, variant: nil, reason: "DEFAULT", metadata: {})
    @value = value
    @variant = variant
    @reason = reason
    @metadata = metadata
  end
end
```

### 2. エラー時の評価結果
```ruby
class ErrorEvaluation
  attr_reader :error_code, :error_message, :default_value

  def initialize(error_code, error_message, default_value)
    @error_code = error_code
    @error_message = error_message
    @default_value = default_value
  end
end
```

## エラー型の定義

### 1. 標準エラー型
```ruby
module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          class Error < StandardError; end

          # フラグが見つからない
          class FlagNotFoundError < Error; end

          # 型変換エラー
          class TypeMismatchError < Error; end

          # パースエラー
          class ParseError < Error; end

          # ターゲティングエラー
          class TargetingKeyMissingError < Error; end

          # 無効なコンテキスト
          class InvalidContextError < Error; end

          # 一般エラー
          class GeneralError < Error; end
        end
      end
    end
  end
end
```

### 2. AWS固有エラー型
```ruby
# AWS AppConfig固有のエラー
class ConfigurationNotFoundError < Error; end
class ThrottlingError < Error; end
class AwsServiceError < Error; end
```

## コンテキスト処理

### 1. コンテキスト構造
```ruby
class EvaluationContext
  attr_reader :targeting_key, :attributes

  def initialize(targeting_key: nil, attributes: {})
    @targeting_key = targeting_key
    @attributes = attributes
  end

  def get_value(key)
    @attributes[key]
  end

  def has_value(key)
    @attributes.key?(key)
  end
end
```

### 2. ターゲティング
- `targeting_key`を使用したユーザーターゲティング
- 属性ベースのターゲティング
- ルールベースのターゲティング

## フラグ解決の実装

### 1. 基本的なフラグ解決
```ruby
def resolve_flag(flag_key, context = nil)
  # 1. キャッシュチェック
  # 2. AWS AppConfigから設定取得
  # 3. 型変換
  # 4. ターゲティング評価
  # 5. 結果をキャッシュ
  # 6. 評価結果を返す
end
```

### 2. 型変換
```ruby
def convert_value(raw_value, target_type)
  case target_type
  when :boolean
    convert_to_boolean(raw_value)
  when :string
    convert_to_string(raw_value)
  when :number
    convert_to_number(raw_value)
  when :object
    convert_to_object(raw_value)
  else
    raise TypeMismatchError, "Unsupported type: #{target_type}"
  end
end
```

## メタデータとフラグ情報

### 1. フラグメタデータ
```ruby
class FlagMetadata
  attr_reader :description, :created_at, :updated_at, :tags

  def initialize(description: nil, created_at: nil, updated_at: nil, tags: [])
    @description = description
    @created_at = created_at
    @updated_at = updated_at
    @tags = tags
  end
end
```

### 2. プロバイダーメタデータ
```ruby
class ProviderMetadata
  attr_reader :name, :version, :capabilities

  def initialize(name: "aws-appconfig", version: nil, capabilities: [])
    @name = name
    @version = version
    @capabilities = capabilities
  end
end
```
