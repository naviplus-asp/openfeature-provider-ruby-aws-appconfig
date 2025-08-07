# OpenFeature AWS AppConfig Provider for Ruby

AWS AppConfigと統合してフィーチャーフラグ管理を行うOpenFeatureのRubyプロバイダーです。

## 機能

- ✅ OpenFeature仕様の完全準拠
- ✅ AWS AppConfig統合（最新のAppConfigData API使用）
- ✅ AppConfig Agentと直接SDKの併存サポート
- ✅ 全データ型のサポート（boolean、string、number、object） - 注意: AWS AppConfigはネイティブでboolean、string、number、配列をサポートしています。オブジェクト型はJSON文字列として保存し、クライアント側でパースします。
- ✅ **マルチバリアントフィーチャーフラグとターゲティングルール**
- ✅ **高度なターゲティングオペレーター（equals、contains、starts_with等）**
- ✅ **複数の属性を含む複雑なターゲティング条件**
- ✅ **効率的な設定取得のためのセッション管理**
- ✅ 包括的なエラーハンドリング
- ✅ 型変換とバリデーション
- ✅ モックを使用したユニットテスト
- ✅ **AppConfig Agentを使用した統合テスト**
- ✅ **Docker Composeによる簡単な統合テスト環境**
- ✅ **GitHub Actions CIによる統合テスト**

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

プロバイダーは自動的に以下を処理します：
- セッションの作成と管理
- セッション期限切れ時のトークン更新
- エラーハンドリングとリトライロジック

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

### マルチバリアントフィーチャーフラグ

このプロバイダーはAWS AppConfigのマルチバリアントフィーチャーフラグとターゲティングルールをサポートしています：

```ruby
# ユーザー属性を含む評価コンテキストを作成
context = OpenFeature::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: {
    "language" => "ja",
    "country" => "JP",
    "plan" => "premium",
    "user_type" => "admin"
  }
)

# コンテキストを使用してマルチバリアントフラグを解決
personalized_message = client.get_string_value("welcome-message", "Hello", context)
discount_percentage = client.get_number_value("discount-percentage", 0, context)
user_theme = client.get_object_value("user-theme", {}, context)
```

### 評価コンテキストを使用

```ruby
# 評価コンテキストを作成
context = OpenFeature::EvaluationContext.new(
  targeting_key: "user-123",
  attributes: {
    "user_id" => "123",
    "country" => "US",
    "plan" => "premium"
  }
)

# コンテキストを使用してフィーチャーフラグを解決
is_feature_enabled = client.get_boolean_value("new-feature", false, context)
```

## テスト

### ユニットテスト（モック使用）
```bash
bundle exec rake test_unit
```

### 統合テスト（AppConfig Agent使用）

#### オプション1: Docker Composeを使用（推奨）

統合テストを簡単に行うためのDocker Compose構成を提供しています：

```bash
# 統合テスト環境を開始
./scripts/start-integration-tests.sh
```

このスクリプトは以下を行います：
1. Dockerが起動しているかチェック
2. ポートの可用性を確認
3. 以下の選択肢から選ばせます：
   - 実際のAppConfig Agent（AWS認証情報が必要）
   - モックサーバー（AWS認証情報不要）
4. 適切なサービスを起動
5. サービスが応答しているか確認

#### オプション2: 手動セットアップ

手動でセットアップしたい場合：

1. **AppConfig Agentのインストールと起動**:
   ```bash
   # AppConfig Agentをインストール（AWSドキュメントに従って）
   # AWS認証情報でエージェントを起動
   ```

2. **AWS AppConfigでテストデータを設定**:
   - アプリケーション作成: `test-integration-app`
   - 環境作成: `test-integration-env`
   - 設定プロファイル作成: `test-integration-profile`
   - テスト設定をデプロイ（期待されるデータは`test/integration_test_helper.rb`を参照）

3. **統合テストを実行**:
   ```bash
   bundle exec rake test_integration
   ```

#### Docker Composeコマンド

```bash
# 実際のAppConfig Agentを起動（AWS認証情報が必要）
docker-compose up -d appconfig-agent

# モックサーバーを起動（AWS認証情報不要）
docker-compose -f docker-compose.mock.yml up -d

# サービスを停止
docker-compose down
docker-compose -f docker-compose.mock.yml down

# ログを表示
docker-compose logs appconfig-agent
docker-compose -f docker-compose.mock.yml logs mock-appconfig-server
```

### 全テスト
```bash
bundle exec rake test_all
```

### テスト構造

- **ユニットテスト**: `test/openfeature/provider/ruby/aws/`に配置
  - AWS SDK呼び出しにモックを使用
  - 高速実行
  - 外部依存関係なし
  - 直接SDKモードとAgentモードの両方をテスト

- **統合テスト**: `test/openfeature/provider/ruby/aws/integration_test_provider.rb`に配置
  - 実際のAppConfig Agentまたはモックサーバーを使用
  - 実際のHTTP通信をテスト
  - AppConfig Agentの起動が必要
  - 実際の設定取得とターゲティングをテスト

### 統合テストの実行

#### セットアップスクリプトを使用

```bash
# 統合テスト環境を開始
./scripts/start-integration-tests.sh

# プロンプトで希望するモードを選択
# その後テストを実行
bundle exec rake test_integration
```

#### 手動Dockerセットアップ

```bash
# モックサーバー用（AWS認証情報不要）
docker-compose -f docker-compose.mock.yml up -d

# 実際のAppConfig Agent用（AWS認証情報が必要）
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_REGION=us-east-1
docker-compose up -d appconfig-agent

# テストを実行
bundle exec rake test_integration
```

## 継続的インテグレーション

### GitHub Actions

このプロジェクトは包括的なCI/CDをGitHub Actionsで提供しています：

- **RuboCop**: コードスタイルと品質チェック
- **ユニットテスト**: 複数Rubyバージョンでのテスト（3.1、3.2、3.3、3.4）
- **統合テスト**:
   - Dockerを使用してモックAppConfigサーバーをセットアップ
   - モックサーバーに対して統合テストを実行
   - 実際のHTTP通信で全ての機能が動作することを確認

#### CIワークフロー

CIパイプラインは全てのプッシュとプルリクエストで実行されます：

1. **RuboCop**: コードスタイルの検証
2. **ユニットテスト**: 複数Rubyバージョンでのテスト
3. **統合テスト**:
   - Dockerを使用してモックAppConfigサーバーをセットアップ
   - モックサーバーに対して統合テストを実行
   - 実際のHTTP通信で全ての機能が動作することを確認

#### CI結果の確認

- リポジトリの[Actionsタブ](https://github.com/naviplus-asp/openfeature-provider-ruby-aws-appconfig/actions)にアクセス
- 各ワークフロー実行で全テスト段階の詳細結果を表示
- 統合テストログにはモックサーバーのセットアップとテスト実行の詳細が含まれます

#### ローカルCIテスト

CIワークフローと同じテストをローカルで実行：

```bash
# CIと同じテストを実行
bundle exec rubocop
bundle exec rake test_unit
bundle exec rake test_integration
```

## AWS AppConfig設定

### シンプルなフィーチャーフラグ

```json
{
  "feature-flag": true,
  "welcome-message": "Hello World!",
  "max-retries": 5,
  "user-config": "{\"theme\": \"dark\", \"language\": \"en\"}"
}
```

**注意**: AWS AppConfigはネイティブでboolean、string、number、配列をサポートしています。オブジェクト型については、AWS AppConfigにJSON文字列として保存してください。プロバイダーは`get_object_value()`を使用する際に自動的にJSON文字列をオブジェクトにパースします。

### マルチバリアントフィーチャーフラグ

このプロバイダーはAWS AppConfigのマルチバリアントフィーチャーフラグ形式をサポートしています：

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

### サポートされているターゲティングオペレーター

このプロバイダーは以下のターゲティングオペレーターをサポートしています：

- `equals`: 完全一致
- `not_equals`: 等しくない
- `contains`: 文字列を含む
- `not_contains`: 文字列を含まない
- `starts_with`: 文字列で始まる
- `ends_with`: 文字列で終わる
- `greater_than`: 数値比較
- `greater_than_or_equal`: 数値比較
- `less_than`: 数値比較
- `less_than_or_equal`: 数値比較

### マルチバリアントフラグ構造

各マルチバリアントフラグは以下を含む必要があります：

1. **`variants`**: `name`と`value`プロパティを持つバリアントオブジェクトの配列
2. **`defaultVariant`**: ターゲティングルールが一致しない場合に使用するデフォルトバリアントの名前
3. **`targetingRules`**（オプション）: ターゲティングルールの配列

各ターゲティングルールは以下を含みます：
- **`conditions`**: 条件の配列（ルールが適用されるには全ての条件が一致する必要がある）
- **`variant`**: 条件が一致した場合に返すバリアントの名前

各条件は以下を含みます：
- **`attribute`**: 評価コンテキストからの属性名
- **`operator`**: 比較オペレーター
- **`value`**: 比較対象の値

### AWS AppConfigセットアップ

1. AWS AppConfigでアプリケーションを作成
2. 環境を作成
3. 設定プロファイルを作成
4. JSON（シンプルまたはマルチバリアント）を含む設定バージョンを作成
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
- **ターゲティングルールエラー**: ターゲティングが失敗した場合のデフォルトバリアントへのフォールバック

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
│   ├── openfeature/provider/ruby/aws/  # ユニットテスト
│   │   ├── test_provider.rb           # メインのユニットテスト
│   │   └── integration_test_provider.rb # 統合テスト
│   └── integration_test_helper.rb     # 統合テストヘルパー
├── docker/
│   ├── appconfig-agent-config.json   # AppConfig Agent設定
│   ├── nginx.conf                    # モックサーバー設定
│   ├── mock-config.json              # モック設定データ
│   └── env.example                   # 環境変数例
├── scripts/
│   └── start-integration-tests.sh    # 統合テスト開始スクリプト
├── docker-compose.yml                # メインDocker Compose設定
├── docker-compose.mock.yml           # モックサーバー用設定
├── .github/workflows/                # GitHub Actionsワークフロー
│   ├── ci.yml                        # メインCIワークフロー
│   └── integration-test.yml          # 統合テスト専用ワークフロー
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

4. **統合テストの失敗**
   - AppConfig Agentが起動しているか確認
   - テスト用の設定が正しくデプロイされているか確認
   - AWS認証情報が正しく設定されているか確認

5. **Docker Composeエラー**
   - Dockerが起動しているか確認
   - ポート2772が使用可能か確認
   - 環境変数が正しく設定されているか確認

6. **GitHub Actions CIエラー**
   - ワークフローログを確認
   - モックサーバーの起動状況を確認
   - テストの実行結果を確認

7. **テスト失敗**
   - 依存関係が正しくインストールされているか確認
   - RuboCopオフセンスを修正

### デバッグ

詳細なログを有効にするには：

```ruby
# ログレベルを設定
OpenFeature::SDK.configure do |config|
  config.logger.level = Logger::DEBUG
end
```

### 統合テストのデバッグ

統合テストで問題が発生した場合：

1. **AppConfig Agentの状態確認**:
   ```bash
   curl http://localhost:2772/applications/test-integration-app/environments/test-integration-env/configurations/test-integration-profile
   ```

2. **AWS認証情報の確認**:
   ```bash
   aws sts get-caller-identity
   ```

3. **AppConfig Agentのログ確認**:
   ```bash
   # Agentのログファイルを確認
   tail -f /var/log/appconfig-agent.log
   ```

4. **Docker Composeログの確認**:
   ```bash
   # 実際のAgentの場合
   docker-compose logs appconfig-agent

   # モックサーバーの場合
   docker-compose -f docker-compose.mock.yml logs mock-appconfig-server
   ```

5. **GitHub Actionsログの確認**:
   - Actionsタブでワークフロー実行を選択
   - 統合テストジョブのログを確認
   - モックサーバーの起動ログを確認
