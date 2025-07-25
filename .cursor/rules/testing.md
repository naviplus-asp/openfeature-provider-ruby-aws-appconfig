# テストルール

## テスト戦略

### 1. テストフレームワーク
- Minitestを使用
- テストファイルは`test/`ディレクトリに配置
- テストファイル名は`test_*.rb`の形式

### 2. テスト構造
```ruby
# 良い例
require "test_helper"

class Openfeature::Provider::Ruby::Aws::AppconfigTest < Minitest::Test
  def setup
    @provider = AppconfigProvider.new
  end

  def test_resolve_flag_returns_correct_value
    # テスト実装
  end

  def test_resolve_flag_handles_errors_gracefully
    # エラーハンドリングのテスト
  end
end
```

### 3. テストカバレッジ
- 新機能追加時は必ずテストを作成
- 公開メソッドは100%カバレッジを目指す
- エラーケースも適切にテスト

### 4. モックとスタブ
```ruby
# AWS SDKのモック例
def test_aws_appconfig_integration
  mock_client = Minitest::Mock.new
  mock_client.expect :get_configuration, mock_response, [expected_params]

  @provider.stub :client, mock_client do
    result = @provider.resolve_flag("test_flag")
    assert_equal expected_value, result
  end

  mock_client.verify
end
```

### 5. テストデータ
- テストデータは`test/fixtures/`に配置
- 機密情報は含めない
- テストデータは明確で理解しやすいものにする

## 統合テスト

### 1. AWS AppConfig統合
- 実際のAWS AppConfigとの統合テスト
- テスト用のAWS環境を用意
- CI/CDでの自動テスト実行

### 2. OpenFeature仕様準拠
- OpenFeatureの仕様に準拠したテスト
- 標準的なフラグ解決のテスト
- エラー型のテスト

## パフォーマンステスト

### 1. レスポンス時間
- フラグ解決のレスポンス時間を測定
- キャッシュの効果を検証
- 負荷テストの実施

### 2. メモリ使用量
- メモリリークの検出
- 長時間実行時の安定性確認
