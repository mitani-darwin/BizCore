# Phase2: Operability Foundation

目的は「運用者が迷わない」「権限・UI・監査ログの三位一体が崩れない」状態を土台から固定すること。

## 主要コンポーネント

### Admin::BaseController
- `authorize!` を必須化し、権限チェックを全アクションで強制
- `audit!` と `around_action` により監査ログの書き忘れを防止
- `required_permission_key` は `Admin::Screens` の定義を優先

### Admin::Navigation
- サイドバー定義を単一ソース化
- `required_keys` のみで可視性を判定し、View には条件分岐を散らさない

### Admin::Screens
- 画面定義（画面構造・アクション・権限キー・パンくず・ページタイトル）を一元管理
- `Admin::BaseController` から参照し、画面追加時の漏れを防止

## 管理画面追加時のテンプレート

1. Controller/Route を追加
2. `Permissions::Catalog` に `admin.{resource}.{action}` を追加
3. `Admin::Screens::SCREEN_DEFS` に画面定義を追加
4. `Admin::Navigation` にメニュー項目を追加
5. `authorize!` と `audit!` を同じ key で使用
6. 必要なら empty state や confirm UI を追加

### 画面定義の例
```
screens: {
  foos: {
    index_path: :admin_foos_path,
    actions: %i[index show new create edit update]
  }
}
```

## UX (運用者向け)
- ページタイトルは `Admin::Screens` から自動補完
- パンくずは `Admin::Screens` の定義を使い自動表示
- 空状態は一覧画面で必ず明示
- 破壊的操作は `turbo_confirm` を必ず付与

## 拡張前提の整理

### built-in ロールとカスタムロール
- `Role#built_in?` を軸に表示/編集/削除可否を分離する
- `Role#editable?` / `Role#deletable?` を入口にガードを追加可能

### Feature Flags / Settings
- `FeatureFlags` と `Settings` を app/models に集約
- 将来的には tenant 単位の永続化ストアに差し替える

### 業種別拡張ポイント
- 業種別メニューや機能は `Admin::Navigation` と `FeatureFlags` で制御
- 標準機能と縦展開機能を明確に分離する

## テスト
- `test/consistency/permission_consistency_test.rb`
- `test/models/admin/screens_test.rb`
- UI / 認可 / 監査ログが常に一致することを固定

## Phase3 への布石
- 画面定義と権限定義を増やしても壊れない構造
- Feature Flags/Settings の導入で業種別機能追加を安全に進められる
