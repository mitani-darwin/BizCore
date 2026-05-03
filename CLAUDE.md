# CLAUDE.md

このファイルは、このリポジトリで Claude がコード生成・設計・修正を行うときの実務ルールをまとめたものです。

## 基本方針

- 出力と説明は基本的に日本語で行う。
- まず既存実装を読む。新しい流儀を持ち込む前に、近い画面・モデル・サービスの実装を踏襲する。
- 古いドキュメントより現在のコードを優先する。特に `PROMPT_FOR_AI.md` は参考資料として扱い、実装と矛盾する場合は現行コードを正とする。

## プロジェクト概要

- 日本の中小企業向け共通業務基盤 SaaS。
- Rails 8.1 系のサーバーレンダリング中心のアプリケーション。
- 論理マルチテナント方式を採用しており、業務データは `tenant_id` で分離する。
- 権限制御はロールベース。管理画面は権限キー単位で制御する。
- 管理画面に加えて、従業員向けセルフ打刻画面も存在する。

## 現在の技術スタック

- Ruby on Rails 8.1
- Propshaft
- Importmap
- Turbo / Stimulus
- Devise
- Pundit
- SQLite3
- Solid Queue / Solid Cache / Solid Cable
- Minitest

注意:
- `PROMPT_FOR_AI.md` には `has_secure_password` 前提の記述があるが、現行実装の認証は `Devise`。
- 将来構成を推測せず、`Gemfile` と既存コードに合わせて実装すること。

## アーキテクチャ上の最重要ルール

### 1. マルチテナント

- 業務テーブルは原則 `tenant_id` を持たせる。
- レコード取得は必ずテナントスコープで行う。
- 典型例:
  - `current_tenant.customers`
  - `current_tenant.employees.find(params[:id])`
- テナントをまたぐ検索や更新をしてはいけない。
- `find` よりも、既存実装に合わせて `current_tenant.<assoc>.find_by(id: ...)` と `render_not_found` を使う実装が多い。

### 2. リクエストコンテキスト

- `ApplicationController` で `Current.user` と `Current.tenant` をセットしている。
- 利用可能なヘルパー:
  - `current_user`
  - `current_tenant`
  - `current_employee`
  - `current_ability`
- ロケールは `current_user.locale` ベースで設定される。

### 3. 認証と権限

- 認証は `Devise`。
- 管理画面コントローラは原則 `Admin::BaseController` を継承する。
- `Admin::BaseController` が以下を面倒を見る:
  - `authenticate_user!`
  - テナント存在確認
  - 画面メタデータ生成
  - 権限チェック
  - 監査ログ
- 権限キーの形式は `admin.<resource>.<action>`。
- `is_owner?` ユーザーは権限を広く通す前提がある。

## 新しい管理画面リソースを追加する場合

新規の管理画面リソースを足すときは、コントローラや view だけで終わらせない。少なくとも次を確認する。

1. `config/routes.rb`
2. `app/models/permissions/catalog.rb`
3. `app/models/admin/screens.rb`
4. `app/models/admin/navigation.rb`
5. 対応する controller / model / view
6. 必要な service object
7. `db/seeds.rb` または権限 seed
8. `test/` 配下のテスト

補足:
- 権限の表示名や画面タイトルは `Permissions::Catalog` と `Admin::Screens` に寄せる。
- サイドバー導線は `Admin::Navigation` で管理する。

## モデル・DB 命名規約

- テーブル名は `snake_case` の複数形。
- モデル名は単数形。
- 外部キーは `*_id`。
- 通常のタイムスタンプは `created_at`, `updated_at`。
- 既存スキーマに合わせ、命名を勝手に変えない。
- 業務上必要でない限り、既存カラムや関連名をリネームしない。

## 実装スタイル

### コントローラ

- 近い既存実装を真似る。例:
  - 一覧: 絞り込みパラメータを private メソッド化
  - 詳細: 月次集計や関連取得はコントローラで整理
  - 作成/更新: strong parameters を明示
- テナント外アクセス時は 404 で返す。
- 管理画面では権限前提の UI を壊さない。

### サービスオブジェクト

- 業務フローは `app/services` に置く。
- 既存の `Orders::SendOrder` や `Payrolls::GenerateRun` と同じ粒度を優先する。
- 複雑な副作用をコントローラに直接書き込まない。

### View

- ERB ベースで実装する。
- 既存の utility class ベースの見た目を踏襲する。
- 文言は日本語を基本とする。
- 権限で表示を切り替える箇所は `can?("admin.resource.action")` の形に合わせる。
- 画面タイトルやパンくずは `Admin::Screens` と整合させる。

### I18n

- 日本語 UI が基本。
- エラーメッセージや認証周りの文言を追加する場合は `config/locales/` を確認する。
- モデル名や属性名の見せ方は既存の `human_attribute_name` 実装も考慮する。

## テスト方針

- テストフレームワークは `Minitest`。
- 新機能追加時は、最低でも近い粒度のテストを追加する。
- 候補:
  - モデルテスト
  - コントローラテスト
  - 統合テスト
  - システムテスト
- seed を変更した場合は seed の再投入で壊れないことを意識する。

## 検証コマンド

変更内容に応じて、以下を使って確認する。

- `bin/rails test`
- `bin/rails test:system`
- `bin/rubocop`
- `bin/bundler-audit`
- `bin/importmap audit`
- `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
- `env RAILS_ENV=test bin/rails db:seed:replant`
- `bin/ci`

## Claude への禁止事項

- テナントスコープを無視した検索をしない。
- 既存の権限カタログに未登録の管理画面を黙って追加しない。
- 近い既存実装があるのに、別流儀の実装へ勝手に置き換えない。
- `PROMPT_FOR_AI.md` の古い記述をうのみにして、現行の Devise 実装を壊さない。
- 日本語 UI 前提の画面で英語文言を混在させない。

## 迷ったときの優先順位

1. 現在のコード
2. テスト
3. この `CLAUDE.md`
4. `PROMPT_FOR_AI.md`

この順で判断すること。
