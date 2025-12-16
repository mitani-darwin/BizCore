あなたは Ruby on Rails 8 の業務SaaS（マルチテナント/RBAC）実装に精通したエンジニアです。
既存プロジェクトに Permission seed（admin.* を一括生成） を追加してください。対象は管理画面 /admin 配下の権限です。

目的
	•	permissions テーブルに admin.<resource>.<action> 形式の権限キーを一括投入
	•	seedは 冪等（何回流しても二重登録しない）
	•	既存Permissionがある場合は name/description などを必要に応じて更新
	•	不要になった権限キーは 削除しない（安全側） ※将来オプション化しても良い
	•	追加した seed を 読みやすく分割（db/seeds.rb から呼ぶ）

---

前提（スキーマ想定）
	•	permissions テーブルが存在
	•	カラム例：key:string (unique), name:string, description:text, created_at, updated_at
	•	まだ key に unique index が無い場合は migration を追加して付与（既存重複があれば安全に対処案も提示）

---

権限キー規則（必須）
	•	admin.<resource>.<action> に統一
	•	action は原則このセット：
index, show, new, create, edit, update, destroy
	•	resource は最初は最低限で良いが、拡張しやすい定義にすること

---

実装要件（重要）

1) seedファイルの追加
	•	db/seeds/permissions_admin.rb を新規作成
	•	PermissionsAdminSeeder.call のように呼べる形（クラス or モジュール）にする
	•	中身は以下の責務を持つ：
	•	生成対象（resources/actions）を定義
	•	Permission.upsert_all か find_or_initialize_by で冪等投入
	•	ログ（puts）で「何件作成/更新したか」を出す

2) db/seeds.rb の更新
	•	require_relative "seeds/permissions_admin" のように読み込み
	•	実行順序のコメントを書く（例：permissions → roles → assignments）

3) 生成対象の設計
	•	resources/actions は “定数” で見通しよく
	•	例：
resources: tenants, users, roles, permissions, role_permissions, assignments, dashboard
※ dashboard は index のみなど、resourceごとに許可actionを変えられる設計にする

4) 表示名(name)/説明(description)
	•	name は人間向け（日本語でOK）：例「テナント一覧を見る」
	•	description は補足（任意）
	•	key から自動生成してもよいが、後で編集しやすい構造にする

5) セーフティ
	•	本番で seed を回しても壊れない（例外で止まらない）
	•	既存の Permission レコードを尊重しつつ、key基準で整合を取る
	•	削除はしない（ただし、オプションで「未使用キー検出」をログ出力は可）

---

出力形式（必須）
	•	変更/追加するファイルを ファイルパス付きで列挙
	•	各ファイルの 全文コード
	•	必要なら migration（unique index）も提示
	•	rails db:seed 実行時に期待されるログ例も出す

---

受け入れ条件
	•	rails db:seed を2回実行しても permissions が増殖しない
	•	追加した resources/actions が即座に permissions に反映される
	•	key が一意に保たれる

この仕様に従って実装してください。