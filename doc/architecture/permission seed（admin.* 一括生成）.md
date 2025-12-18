あなたは Rails 8 / 業務システム向けマルチテナントSaaS の設計・実装に精通したエンジニアです。
管理画面 Admin:: 配下で使用する Permission（権限）を admin.* という命名規則で一括生成する seed 基盤を実装してください。

この Permission は以下すべてで 完全に同一の key を使う前提です。
	•	認可（authorize!(key) / can?(key)）
	•	UI出し分け（サイドバー・ボタン）
	•	監査ログ（AuditLog.action_key）

⸻

ゴール（成果物）
	1.	permissions テーブル & Permission モデル
	2.	admin.* を一括生成する seed（再実行可能・冪等）
	3.	Permission の設計思想を説明する doc/architecture/permissions/README.md
	4.	AuditLog.action_key と一致させるための 命名ルールを明文化
	5.	「Permissionをコードから増やす正しいやり方」が分かる状態

⸻

前提条件・制約
	•	Rails 8
	•	マルチテナントSaaS
	•	権限は テナント単位（Permission定義自体は共通、割当はテナント別）
	•	Role / Assignment は まだ作らない
	•	Permission は「できることの辞書」として扱う（状態を持たない）
	•	seed は 何度実行しても壊れない
	•	admin 画面に存在する機能は 必ず Permission として定義される文化を作る

⸻

Permission モデル設計

テーブル: permissions
| column | type | note |
| id     | bigint | |
| key    | string | 例: admin.tenants.update（一意） |
| name | string |表示名（日本語可） |
| description | text | 何ができるか |
| category | string | 例: tenants, users, roles, audit_logs |
| created_at |datetime | |
| updated_at | datetime |

	•	key に unique index
	•	category はUI grouping用
	•	将来 built_in: true を追加できる余地を残す（今は不要）

⸻

Permission key 命名規則（超重要）
```
admin.{resource}.{action}
```

resource 例
	•	tenants
	•	users
	•	roles
	•	permissions
	•	audit_logs

action 例
	•	read
	•	create
	•	update
	•	delete
	•	manage（複合操作）

例
	•	admin.tenants.read
	•	admin.tenants.create
	•	admin.tenants.update
	•	admin.tenants.delete
	•	admin.audit_logs.read

⚠ AuditLog.action_key と 完全一致させること

⸻

admin.* Permission 一括生成仕様

対象リソース（初期）
	•	tenants
	•	users
	•	roles
	•	permissions
	•	audit_logs

生成アクション
	•	read
	•	create
	•	update
	•	delete
（audit_logs は read のみ）

⸻

実装要件

1) migration & model
	•	permissions テーブルを作成
	•	Permission モデルを作成
	•	validation: key presence / uniqueness

⸻

2) Seed 実装（重要）

要件
	•	rails db:seed を 何度実行しても同じ状態
	•	差分があれば更新（name / description）
	•	削除はしない（将来の互換性を守る）

実装方針
	•	db/seeds/permissions/admin_permissions.rb に切り出す
	•	db/seeds.rb から require
	•	Rubyの配列・ハッシュで 明示的に定義（自動生成でも可だが「読める」ことを優先）

⸻

3) Seed 定義例（概念）
```
ADMIN_RESOURCES = {
  tenants: %i[read create update delete],
  users: %i[read create update delete],
  roles: %i[read create update delete],
  permissions: %i[read],
  audit_logs: %i[read]
}
```

これをループして
	•	key: "admin.#{resource}.#{action}"
	•	name: "テナント#{action_日本語}"
	•	category: resource

を生成する

⸻

4) ドキュメント

doc/architecture/permissions/README.md
最低限含めること：
	•	Permission の役割（Roleとは違う）
	•	なぜ admin.* を seed で固定するのか
	•	action_key === permission.key という思想
	•	新しい admin 機能を追加する時の手順
	1.	Controller / UI を作る
	2.	Permission を seed に追加
	3.	authorize / can? を書く
	4.	監査ログに action_key を書く

⸻

出力形式（厳守）
	•	ファイルパス
	•	コード全文
	•	README.md の本文

コピペして即使える状態で、すべて出力してください。

⸻

最重要メッセージ

この Permission seed は UI・認可・監査ログの“共通語彙” です。
「管理画面に存在する操作は、必ず admin.* Permission が存在する」
この文化をコードで強制できる実装にしてください。

⸻

このプロンプトに従って、必要なファイルをすべて生成してください。




