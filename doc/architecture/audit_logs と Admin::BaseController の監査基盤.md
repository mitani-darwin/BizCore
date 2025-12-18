あなたは Rails 8 で 業務システム向けマルチテナントSaaS を実装する熟練エンジニアです。
管理画面 Admin:: に対して 監査ログ（誰がいつ何をした） を必ず残す基盤を実装してください。

前提
	•	Rails 8
	•	DB は開発 SQLite
	•	マルチテナントで tenant_id を必須にしたい
	•	管理画面の基底コントローラは Admin::BaseController にする
	•	認証・権限はまだ未実装でもOK（将来 current_user が入る前提の形にする）
	•	監査ログは 成功だけでなく拒否/例外も将来残せる拡張性を持たせる
	•	監査ログの “キー” は将来 Permission key と一致させるため action_key を持たせる（例: admin.tenants.update）

ゴール（成果物）
	1.	AuditLog モデルと audit_logs テーブルの migration を作成
	2.	Admin::BaseController に監査ログ基盤（around_action / helper / request情報収集）を実装
	3.	管理画面の各アクションから 簡単に記録できるAPI を用意（例: audit!(action_key:, auditable:, metadata:)）
	4.	Admin::TenantsController の update を例に、監査ログが記録される実装例を追加
	5.	最低限のRSpec（またはMinitest）で「updateすると AuditLog が1件増える」テストを1本追加
	6.	実装ファイルの配置パスを明記し、必要なコードをすべて出力する

⸻

仕様詳細

audit_logs テーブル仕様

カラム（必須/推奨）
	•	tenant_id : bigint, null: false, index
	•	actor_type : string, null: true（polymorphic用。まずは “User” 想定）
	•	actor_id : bigint, null: true, index
	•	action_key : string, null: false, index（例: admin.tenants.update）
	•	auditable_type : string, null: true
	•	auditable_id : bigint, null: true, index
	•	request_id : string, null: true, index
	•	ip_address : string, null: true
	•	user_agent : string, null: true
	•	path : string, null: true
	•	http_method : string, null: true
	•	status : string, null: false, default: “succeeded”（succeeded/failed/denied を想定）
	•	metadata : json (Postgres) / text (SQLite) 互換を考慮して実装
	•	created_at : datetime

metadata の互換性:
	•	Postgres では jsonb
	•	SQLite では text に JSON を保存して serialize
	•	Railsの serialize :metadata, coder: JSON などで吸収してよい
	•	可能なら migration 側で adapter を見て型を切り替える（難しければモデルで吸収）

モデル仕様

AuditLog モデル
	•	belongs_to :tenant
	•	belongs_to :actor, polymorphic: true, optional: true
	•	belongs_to :auditable, polymorphic: true, optional: true
	•	validations: tenant_id, action_key, status
	•	status は enum でも string でもOK（まずは string でシンプルでも良い）

Admin::BaseController 仕様
	•	around_action :with_audit_context
	•	helper_method :audit_context（必要なら）
	•	audit_context に以下を格納
	•	tenant_id（取得方法は Current.tenant などがあればそれ。なければ仮で current_tenant を用意しTODO）
	•	actor（current_user があればそれ。なければ nil）
	•	request_id, ip_address, user_agent, path, method
	•	audit!(action_key:, auditable: nil, metadata: {}, status: "succeeded") を用意し、DBに保存
	•	例外時に status: "failed" で記録できるよう拡張ポイントを入れる（今すぐ全例外を記録しなくてもOKだが、設計は入れる）

例: Admin::TenantsController#update
	•	audit!(action_key: "admin.tenants.update", auditable: @tenant, metadata: { changed: ... }) のように記録
	•	metadata の差分は簡易でOK（saved_changes を使う、または変更された属性名配列でもよい）

テスト
	•	Admin::TenantsController#update を叩いて AuditLog.count が増えること
	•	action_key が期待値であること
	•	tenant_id が入っていること（仮でも良いが、入るようにする）

⸻

追加要件（重要）
	•	生成するコードは 実運用で破綻しないこと（NULL許容やインデックス含め）
	•	“監査ログを残す責務” を controller に散らさず、BaseControllerに寄せること
	•	action_key は将来 Permission key と一致させる前提で、文字列を統一しやすい形にする
	•	出力は「ファイルパス → コード全文」の形式で、コピペしてそのまま作れるようにする

⸻

このプロンプトに従って、必要なファイルを全て生成してください。