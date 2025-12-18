# 網羅テスト3点セット（完全一致チェック）

## 目的
次の三位一体が崩れないことを自動テストで固定します。

1. UI に表示される = `can?(permission_key)` が true
2. 実行できる = `authorize!(permission_key)` が通る
3. 実行された = `AuditLog.action_key == permission_key`

## テスト構成
ファイル: `test/consistency/permission_consistency_test.rb`

### テスト1: Routes/Controller × Permission key の整合
- Admin:: 配下の routes を列挙
- REST 規約で permission key を導出
- Permission に存在することを検証

### テスト2: Navigation × Permission key の整合
- `Admin::Navigation` の required_keys を再帰走査
- Permission に存在することを検証

### テスト3: 監査ログ action_key の一致
- 代表アクション（例: tenants#update）を実行
- AuditLog の `action_key` が Permission key と一致することを検証
- `tenant_id` が入ることを検証

## 失敗時の読み方
- Routes テストが失敗: ルーティングが増えたが Permission が未定義
- Navigation テストが失敗: メニューにタイポまたは未登録の Permission
- 監査ログテストが失敗: 実行ログと Permission key がずれている

## 新規画面追加時の手順
1. Controller / View を追加
2. `Permissions::Catalog` に permission を追加
3. `Admin::Navigation` に required_keys を追加
4. 必要なら監査ログの `action_key` を同じ key にする
