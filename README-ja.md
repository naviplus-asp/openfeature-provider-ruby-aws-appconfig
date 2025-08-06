# OpenFeature AWS AppConfig Provider for Ruby

AWS AppConfigと統合してフィーチャーフラグ管理を行うOpenFeatureのRubyプロバイダーです。

## 機能

- ✅ OpenFeature仕様の完全準拠
- ✅ AWS AppConfig統合（最新のAppConfigData API使用）
- ✅ AppConfig Agentと直接SDKの併存サポート
- ✅ 全データ型のサポート（boolean、string、number、object） - 注意: AWS AppConfigはネイティブでboolean、string、number、配列をサポートしています。オブジェクト型はJSON文字列として保存し、クライアント側でパースします。
- ✅ 包括的なエラーハンドリング
- ✅ 型変換とバリデーション
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

## 動作モード

このプロバイダーは2つの動作モードをサポートしています：

### 直接SDKモード（デフォルト）
最新のAWS AppConfigData APIを直接使用します。このモードの特徴：

- **無料API呼び出し**: 設定取得に料金がかからない
- **セッション管理**: 効率的な設定取得とセッショントークン管理
- **パフォーマンス向上**: 頻繁な設定アクセスに最適化
- **将来性**: AWS推奨のAPIを使用
- **クライアントサイドターゲティング**: カスタムターゲティングロジック評価

### Agentモード
AWS AppConfig Agentを使用して設定を取得します。このモードの特徴：

- **サーバーサイドターゲティング**: より安全なターゲティングルール評価
- **ローカルエンドポイント**: 効率的なローカルHTTP APIアクセス
- **認証簡素化**: AgentがAWS認証情報を管理
- **ネットワーク効率**: AWS API呼び出しの削減

### モード選択

```ruby
# 直接SDKモード（デフォルト）
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1",
  mode: :direct_sdk  # または省略
)

# Agentモード
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  mode: :agent,
  agent_endpoint: "http://localhost:2772"  # デフォルトエンドポイント
)
```

## 使用方法

### 基本的な使用方法

```ruby
require "open_feature/sdk"
require "openfeature/provider/ruby/aws/appconfig"

# OpenFeatureクライアントを初期化
client = OpenFeature::SDK::Client.new

# AWS AppConfigプロバイダーを作成して登録（直接SDKモード）
provider = Openfeature::Provider::Ruby::Aws::Appconfig::Provider.new(
  application: "my-application",
  environment: "production",
  configuration_profile: "feature-flags",
  region: "us-east-1",
  mode: :direct_sdk  # デフォルト
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

#### 共通パラメータ
- `mode`: 動作モード（`:direct_sdk` または `:agent`、デフォルト: `:direct_sdk`）

#### 直接SDKモード用パラメータ
- `region`: AWSリージョン（デフォルト: "us-east-1"）
- `credentials`: AWS認証情報（デフォルト: AWS SDKのデフォルト認証チェーンを使用）
- `endpoint_url`: カスタムエンドポイントURL（カスタムエンドポイントでのテストに便利）
- `client`: カスタムAWS AppConfigDataクライアント

#### Agentモード用パラメータ
- `agent_endpoint`: AppConfig Agentエンドポイント（デフォルト: "http://localhost:2772"）
- `agent_http_client`: カスタムHTTPクライアント（テスト用）

## 開発

### 前提条件

- Ruby 3.1以上
- AWS CLI（オプション、AWS AppConfigテスト用）

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

### テストの実行

#### ユニットテスト（モック使用）
```bash
bundle exec rake test_unit
```

#### 全テスト
```bash
bundle exec rake test
```

### テスト構造

- **ユニットテスト**: `test/openfeature/provider/ruby/aws/`に配置
  - AWS SDK呼び出しにモックを使用
  - 高速実行
  - 外部依存関係なし
  - 直接SDKモードとAgentモードの両方をテスト

## AWS AppConfig設定

### 設定JSONの例

```json
{
  "feature-flag": true,
  "welcome-message": "Hello World!",
  "max-retries": 5,
  "user-config": "{\"theme\": \"dark\", \"language\": \"en\"}"
}
```

**注意**: AWS AppConfigはネイティブでboolean、string、number、配列をサポートしています。オブジェクト型については、AWS AppConfigにJSON文字列として保存してください。プロバイダーは`get_object_value()`を使用する際に自動的にJSON文字列をオブジェクトにパースします。

### AWS AppConfigセットアップ

1. AWS AppConfigでアプリケーションを作成
2. 環境を作成
3. 設定プロファイルを作成
4. JSONを含む設定バージョンを作成
5. 設定をデプロイ

### AppConfig Agentセットアップ（Agentモード使用時）

1. AppConfig Agentをインストール
2. Agentを設定して起動
3. デフォルトエンドポイント（http://localhost:2772）でアクセス可能にする

## エラーハンドリング

プロバイダーは様々なエラーシナリオを処理します：

- **設定が見つからない**: 適切なメッセージでエラーを返す
- **スロットリング**: AWSスロットリング例外を処理
- **パースエラー**: JSONパースエラーを処理
- **型変換**: 型の不一致を適切に処理
- **セッション期限切れ**: 自動セッション更新（直接SDKモード）
- **HTTPエラー**: AgentモードでのHTTP通信エラー処理

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
│       ├── client.rb                # AWS SDKクライアント
│       ├── agent_client.rb          # AppConfig Agentクライアント
│       └── version.rb               # バージョン情報
├── test/
│   └── openfeature/provider/ruby/aws/  # ユニットテスト
├── examples/                        # 使用例
└── sig/                            # RBS型定義
```

## トラブルシューティング

### よくある問題

1. **AWS認証エラー**
   - AWS認証情報が正しく設定されているか確認
   - IAMロールとポリシーを確認

2. **AWS AppConfig接続エラー**
   - AWS認証情報が正しく設定されているか確認
   - AppConfigリソースが存在するか確認

3. **Agentモードでの接続エラー**
   - AppConfig Agentが起動しているか確認
   - エンドポイントURLが正しいか確認
   - ネットワーク接続を確認

4. **テスト失敗**
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

### モード選択のガイドライン

#### 直接SDKモードを選択する場合
- シンプルなセットアップが必要
- AWS認証情報が利用可能
- カスタムターゲティングロジックが必要
- 外部コンポーネントを追加したくない

#### Agentモードを選択する場合
- サーバーサイドターゲティングが必要
- ローカルエンドポイントでのアクセスが必要
- AWS認証情報の管理を簡素化したい
- ネットワーク効率を重視する
