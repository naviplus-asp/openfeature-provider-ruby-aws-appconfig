# コーディング標準

## Ruby コーディング規約

### 1. 基本的なスタイル
```ruby
# 良い例
class AppconfigProvider
  def initialize(config = {})
    @config = config
  end

  def resolve_flag(flag_key, context = nil)
    # 実装
  end
end

# 悪い例
class appconfig_provider
  def initialize config={}
    @config=config
  end
end
```

### 2. メソッド定義
- メソッド名はスネークケース
- 引数にデフォルト値がある場合は`=`の前後にスペースを入れない
- ブロック引数は`|param|`の形式

### 3. 変数と定数
- 変数名はスネークケース
- 定数名は大文字のスネークケース
- インスタンス変数は`@`で始める
- クラス変数は`@@`で始める

### 4. 条件分岐
```ruby
# 良い例
if condition
  do_something
elsif other_condition
  do_other_thing
else
  do_default
end

# 三項演算子は短い場合のみ
result = condition ? true_value : false_value
```

### 5. エラーハンドリング
```ruby
# 良い例
begin
  risky_operation
rescue SpecificError => e
  handle_specific_error(e)
rescue StandardError => e
  handle_general_error(e)
ensure
  cleanup
end
```

## OpenFeature固有の規約

### 1. プロバイダー実装
- OpenFeatureの仕様に準拠
- 適切なエラー型を返す
- コンテキスト情報を適切に処理

### 2. AWS AppConfig統合
- AWS SDKのベストプラクティスに従う
- 適切な認証情報の管理
- エラー時の適切なフォールバック

### 3. パフォーマンス
- キャッシュの適切な実装
- 非同期処理の検討
- メモリ使用量の最適化
