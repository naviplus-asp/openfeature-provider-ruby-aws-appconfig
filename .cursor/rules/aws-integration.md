# AWS AppConfig統合ルール

## AWS SDK使用ガイドライン

### 1. AWS SDK for Ruby
```ruby
# 良い例
require "aws-sdk-appconfig"

class AppconfigProvider
  def initialize(config = {})
    @client = Aws::AppConfig::Client.new(
      region: config[:region] || "us-east-1",
      credentials: config[:credentials]
    )
  end
end
```

### 2. 認証情報管理
- AWS認証情報は環境変数またはIAMロールを使用
- ハードコーディングは絶対に避ける
- 開発環境ではAWS CLIの設定を活用

### 3. エラーハンドリング
```ruby
# AWS SDKエラーの適切な処理
def get_configuration(application, environment, configuration_profile)
  @client.get_configuration(
    application: application,
    environment: environment,
    configuration_profile: configuration_profile
  )
rescue Aws::AppConfig::Errors::ResourceNotFoundException => e
  raise ConfigurationNotFoundError, "Configuration not found: #{e.message}"
rescue Aws::AppConfig::Errors::ThrottlingException => e
  raise ThrottlingError, "Request throttled: #{e.message}"
rescue Aws::AppConfig::Errors::ServiceError => e
  raise AwsServiceError, "AWS service error: #{e.message}"
end
```

## AppConfig固有の実装

### 1. 設定取得
- `get_configuration` APIを使用
- 適切なキャッシュ戦略を実装
- 設定変更の監視機能を検討

### 2. パフォーマンス最適化
```ruby
# キャッシュ実装例
class AppconfigProvider
  def initialize(config = {})
    @cache = {}
    @cache_ttl = config[:cache_ttl] || 300 # 5分
  end

  def resolve_flag(flag_key, context = nil)
    cache_key = generate_cache_key(flag_key, context)

    if cached_value = @cache[cache_key]
      return cached_value if cached_value[:expires_at] > Time.now
    end

    # 新しい値を取得してキャッシュ
    value = fetch_from_appconfig(flag_key, context)
    @cache[cache_key] = {
      value: value,
      expires_at: Time.now + @cache_ttl
    }

    value
  end
end
```

### 3. 設定の型変換
- AppConfigから取得したJSONを適切な型に変換
- OpenFeatureの仕様に準拠した型を返す
- 型変換エラーの適切な処理

## セキュリティ考慮事項

### 1. IAM権限
- 最小権限の原則に従う
- 必要なAppConfig権限のみを付与
- 読み取り専用権限を推奨

### 2. ネットワークセキュリティ
- VPC内からのアクセスを推奨
- 適切なセキュリティグループの設定
- HTTPS通信の強制

### 3. データ保護
- 機密設定の適切な暗号化
- ログに機密情報を出力しない
- 設定値の適切な検証

## 監視とログ

### 1. メトリクス
- 設定取得の成功率
- レスポンス時間
- キャッシュヒット率

### 2. ログ出力
```ruby
# 適切なログ出力例
def resolve_flag(flag_key, context = nil)
  logger.info("Resolving flag", flag_key: flag_key, context: context)

  begin
    result = fetch_from_appconfig(flag_key, context)
    logger.info("Flag resolved successfully", flag_key: flag_key, value: result)
    result
  rescue => e
    logger.error("Failed to resolve flag", flag_key: flag_key, error: e.message)
    raise
  end
end
```
