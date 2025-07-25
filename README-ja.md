# OpenFeature AWS AppConfig Provider for Ruby

AWS AppConfigと統合してフィーチャーフラグ管理を行うOpenFeatureのRubyプロバイダーです。

## 機能

- ✅ OpenFeature仕様の完全準拠
- ✅ AWS AppConfig統合
- ✅ 全データ型のサポート（boolean、string、number、object）
- ✅ 包括的なエラーハンドリング
- ✅ 型変換とバリデーション
- ✅ LocalStackを使用した統合テスト
- ✅ モックを使用したユニットテスト

## インストール

アプリケーションのGemfileに以下の行を追加してください：

```ruby
gem "openfeature-provider-ruby-aws-appconfig"
```

そして以下のコマンドを実行してください：

```bash
bundle install
```

## 使用方法

### 基本的な使用方法

```ruby
require "open_feature/sdk"
require "openfeature/provider/ruby/aws/appconfig"

# OpenFeatureクライアントを初期化
client = OpenFeature::SDK::Client.new

# AWS AppConfigプロバイダーを作成して登録
provider = Openfeature::Provider::Ruby::Aws::Appconfig.create_provider(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1"
)

client.set_provider(provider)

# フィーチャーフラグを解決
is_feature_enabled = client.get_boolean_value("new-feature", false)
welcome_message = client.get_string_value("welcome-message", "Welcome!")
max_retries = client.get_number_value("max-retries", 3)
user_config = client.get_object_value("user-config", {})
```

### 評価コンテキストを使用

```ruby
# 評価コンテキストを作成
context = OpenFeature::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: {
    "country" => "US",
    "plan" => "premium"
  }
)

# コンテキスト付きでフラグを解決
personalized_feature = client.get_boolean_value("personalized-feature", false, context)
```

### プロバイダーの直接使用

```ruby
# プロバイダーを直接作成
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1"
)

# フラグを直接解決
result = provider.resolve_boolean_value("feature-flag")
puts "値: #{result.value}"
puts "バリアント: #{result.variant}"
puts "理由: #{result.reason}"
```

## 設定

### 必須パラメータ

- `application`: AWS AppConfigアプリケーション名
- `environment`: AWS AppConfig環境名
- `configuration_profile`: AWS AppConfig設定プロファイル名

### オプションパラメータ

- `region`: AWSリージョン（デフォルト: "us-east-1"）
- `credentials`: AWS認証情報（デフォルト: AWS SDKのデフォルト認証チェーンを使用）
- `endpoint_url`: カスタムエンドポイントURL（LocalStackテストに便利）

## 開発

### 前提条件

- Ruby 3.1以上
- DockerとDocker Compose（統合テスト用）
- AWS CLI（オプション、LocalStackテスト用）

### セットアップ

1. リポジトリをクローン：
```bash
git clone <repository-url>
cd openfeature-provider-ruby-aws-appconfig
```

2. 依存関係をインストール：
```bash
bundle install
```

3. 統合テスト用にLocalStackをセットアップ：
```bash
./scripts/setup_localstack.sh
```

### テストの実行

#### ユニットテスト（モック使用）
```bash
bundle exec rake test:unit
```

#### 統合テスト（LocalStack使用）
```bash
bundle exec rake test:integration
```

#### 全テスト
```bash
bundle exec rake test
```

#### Dockerベースのテスト
```bash
# LocalStackとDockerで全テストを実行
docker-compose up test-runner

# LocalStackのみ実行
docker-compose up localstack

# 全サービスを停止
docker-compose down
```

### テスト構造

- **ユニットテスト**: `test/openfeature/provider/ruby/aws/`に配置
  - AWS SDK呼び出しにモックを使用
  - 高速実行
  - 外部依存関係なし

- **統合テスト**: `test/integration/`に配置
  - 実際のAWS AppConfigシミュレーションにLocalStackを使用
  - 実際のAWS API相互作用をテスト
  - より包括的だが低速

## AWS AppConfig設定

### 設定JSONの例

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

### AWS AppConfigセットアップ

1. AWS AppConfigでアプリケーションを作成
2. 環境を作成
3. 設定プロファイルを作成
4. JSONを含む設定バージョンを作成
5. 設定をデプロイ

## エラーハンドリング

プロバイダーは様々なエラーシナリオを処理します：

- **設定が見つからない**: 適切なメッセージでエラーを返す
- **スロットリング**: AWSスロットリング例外を処理
- **パースエラー**: JSONパースエラーを処理
- **型変換**: 型の不一致を適切に処理

## 貢献

1. リポジトリをフォーク
2. フィーチャーブランチを作成
3. 変更を加える
4. 変更に対するテストを追加
5. テストスイートを実行
6. プルリクエストを提出

## ライセンス

このgemはMITライセンスの条件の下でオープンソースとして利用可能です。

## サポート

問題や質問については：

1. [OpenFeature仕様](https://openfeature.dev/specification/)を確認
2. AWS AppConfigドキュメントを確認
3. このリポジトリでissueを作成

## プロジェクト構造

```
openfeature-provider-ruby-aws-appconfig/
├── lib/
│   └── openfeature/provider/ruby/aws/appconfig/
│       ├── provider.rb              # メインプロバイダークラス
│       ├── localstack_helper.rb     # LocalStack統合ヘルパー
│       └── version.rb               # バージョン情報
├── test/
│   ├── integration/                 # 統合テスト
│   └── openfeature/provider/ruby/aws/  # ユニットテスト
├── examples/                        # 使用例
├── scripts/                         # セットアップスクリプト
├── docker-compose.yml              # Docker Compose設定
└── Dockerfile.test                 # テスト用Dockerfile
```

## トラブルシューティング

### よくある問題

1. **AWS認証エラー**
   - AWS認証情報が正しく設定されているか確認
   - IAMロールとポリシーを確認

2. **LocalStack接続エラー**
   - LocalStackが正常に起動しているか確認
   - ポート4566が利用可能か確認

3. **テスト失敗**
   - 依存関係が正しくインストールされているか確認
   - RuboCopオフセンスを修正

### デバッグ

詳細なログを有効にするには：

```ruby
# デバッグログを有効化
OpenFeature::SDK.configure do |config|
  config.logger.level = Logger::DEBUG
end
```
