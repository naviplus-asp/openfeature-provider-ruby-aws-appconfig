# OpenFeature AWS AppConfig Provider - 一般ルール

## プロジェクト概要
このプロジェクトは、OpenFeatureのAWS AppConfigプロバイダーを実装するRuby gemです。

## 基本ルール

### 1. コードスタイル
- Ruby 3.1以上をターゲットとする
- 文字列リテラルは二重引用符（"）を使用
- `frozen_string_literal: true`を各ファイルの先頭に配置
- RuboCopの設定に従う

### 2. ファイル構造
- メインのコードは`lib/openfeature/provider/ruby/aws/appconfig/`に配置
- テストは`test/`ディレクトリに配置
- 型定義は`sig/`ディレクトリに配置

### 3. 命名規則
- モジュール名: `Openfeature::Provider::Ruby::Aws::Appconfig`
- ファイル名: スネークケース（例: `appconfig.rb`）
- クラス名: パスカルケース（例: `Appconfig`）

### 4. エラーハンドリング
- カスタムエラーは`Openfeature::Provider::Ruby::Aws::Appconfig::Error`を継承

### 5. ドキュメント
- 公開メソッドには適切なコメントを追加
- README.mdを最新に保つ
- CHANGELOG.mdで変更履歴を管理

## 開発ガイドライン
- 新機能追加時はテストを必ず作成
- リリース前にRuboCopチェックを実行
- セマンティックバージョニングに従う
