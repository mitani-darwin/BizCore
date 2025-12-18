# Permission 設計と運用ルール

## Permission の役割
- Permission は「できることの辞書」です。状態を持たず、機能の存在を表す固定のキーになります。
- Role はテナント単位で Permission を束ねる概念です（誰がどの Permission を持つか）。
- Permission 自体はマルチテナント共通で定義し、割当だけをテナント別に行います。

## admin.* を seed で固定する理由
- UI / 認可 / 監査ログで同じキーを使う「共通語彙」を作るためです。
- `db:seed` を何度実行しても壊れないよう、定義の追加・更新のみ行います（削除はしない）。
- 管理画面に存在する操作は、必ず admin.* Permission が存在する文化を徹底します。

## 命名規則（action_key と完全一致）
```
admin.{resource}.{action}
```

action の例:
- read（index/show などの閲覧）
- create
- update
- delete
- manage（複合操作が必要な場合）

例:
- admin.tenants.read
- admin.tenants.create
- admin.tenants.update
- admin.tenants.delete
- admin.audit_logs.read

AuditLog.action_key も **Permission.key と完全一致**させます。

## seed の実体
- 定義ファイル: `db/seeds/permissions/admin_permissions.rb`
- `db/seeds.rb` から読み込まれます
- 追加・変更したい場合は RESOURCES に追記します

## 新しい管理機能を追加する手順
1. Controller / UI を作る
2. `db/seeds/permissions/admin_permissions.rb` に Permission を追加
3. `authorize!` / `can?` を使って認可を書く
4. 監査ログに `action_key` を書く（Permission.key と同一）

この流れを守ることで、UI・認可・監査ログのキーが一貫します。
