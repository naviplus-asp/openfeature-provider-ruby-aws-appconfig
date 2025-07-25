# 開発ワークフロー

## 開発環境セットアップ

### 1. 初期セットアップ
```bash
# リポジトリのクローン
git clone <repository-url>
cd openfeature-provider-ruby-aws-appconfig

# 依存関係のインストール
bundle install

# 開発環境のセットアップ
bin/setup
```

### 2. 開発用コマンド
```bash
# インタラクティブコンソール
bin/console

# テスト実行
bundle exec rake test

# RuboCopチェック
bundle exec rubocop

# 全チェック実行
bundle exec rake
```

## Gitワークフロー

### 1. ブランチ戦略
- `main`: 本番リリース用ブランチ
- `develop`: 開発用ブランチ
- `feature/*`: 新機能開発用ブランチ
- `fix/*`: バグ修正用ブランチ
- `release/*`: リリース準備用ブランチ

### 2. コミットメッセージ
```
feat: 新機能の追加
fix: バグ修正
docs: ドキュメント更新
style: コードスタイル修正
refactor: リファクタリング
test: テスト追加・修正
chore: その他の変更
```

### 3. プルリクエスト
- 新機能追加時は必ずプルリクエストを作成
- レビューを経てからマージ
- テストが通ることを確認
- RuboCopチェックが通ることを確認

## テスト戦略

### 1. テスト実行
```bash
# 全テスト実行
bundle exec rake test

# 特定のテストファイル実行
bundle exec ruby -I test test/test_appconfig.rb

# テストカバレッジ確認
bundle exec rake test:coverage
```

### 2. テスト環境
- ローカル開発時はモックを使用
- CI/CDでは実際のAWS環境を使用
- テスト用のAWS AppConfig設定を用意

## リリースプロセス

### 1. バージョン管理
```ruby
# lib/openfeature/provider/ruby/aws/appconfig/version.rb
module Openfeature
  module Provider
    module Ruby
      module Aws
        module Appconfig
          VERSION = "0.1.0"
        end
      end
    end
  end
end
```

### 2. リリース手順
```bash
# バージョン番号更新
# version.rbを編集

# テスト実行
bundle exec rake test

# RuboCopチェック
bundle exec rubocop

# ローカルインストールテスト
bundle exec rake install

# リリース実行
bundle exec rake release
```

### 3. セマンティックバージョニング
- MAJOR: 破壊的変更
- MINOR: 新機能追加（後方互換）
- PATCH: バグ修正（後方互換）

## CI/CD設定

### 1. GitHub Actions
```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby-version: [3.1, 3.2, 3.3]

    steps:
    - uses: actions/checkout@v3
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{ matrix.ruby-version }}
    - run: bundle install
    - run: bundle exec rake test
    - run: bundle exec rubocop
```

### 2. 品質チェック
- テストカバレッジの確認
- RuboCopによるコード品質チェック
- セキュリティスキャン
- 依存関係の脆弱性チェック

## ドキュメント管理

### 1. README.md
- プロジェクト概要
- インストール方法
- 使用方法
- 設定例
- 貢献方法

### 2. CHANGELOG.md
- バージョンごとの変更履歴
- 新機能、修正、破壊的変更の記録
- セマンティックバージョニングに従う

### 3. API ドキュメント
- 公開メソッドの説明
- パラメータと戻り値の詳細
- 使用例の提供
