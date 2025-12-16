あなたは「Rails 8」と「業務システム向けマルチテナントSaaS」の設計・実装に精通したエンジニアです。
既に Tenant / User / Role の作成はできている前提で、管理画面（/admin）に権限を確実に効かせる実装を行ってください。

ゴール
	•	管理画面の全Controllerで 権限チェックが必ず動く（直URL叩きでも防げる）
	•	View（メニュー・ボタン）も 権限に応じて表示/非表示
	•	マルチテナント境界を守る（必ず Current.tenant スコープ）
	•	ログイン未実装なので 仮ログイン（User.first） で動くようにする（後で差し替え可能）

---

1. 前提の権限モデル（RBAC）

以下のテーブル/関連を実装または不足分を追加してください。
	•	tenants
	•	users（tenant_id）
	•	roles（tenant_id, key, name, built_in:boolean）
	•	permissions（key, name, description）
	•	role_permissions（role_id, permission_id）
	•	assignments（tenant_id, user_id, role_id）※ user_role の中間

関連（ActiveRecord）
	•	User has_many :assignments
	•	User has_many :roles, through: :assignments
	•	Role has_many :permissions, through: :role_permissions
	•	User has_many :permissions, through: :roles
	•	すべて tenant でスコープできる構造にする（permissions はグローバルでもOK、roles/assignmentsは tenant単位）

---

2. 権限キーの設計（重要）

権限キーは次の命名規則に統一してください。
	•	admin.<resource>.<action>
例）
	•	admin.tenants.index
	•	admin.tenants.show
	•	admin.tenants.create
	•	admin.tenants.update
	•	admin.roles.index
	•	admin.roles.update
	•	admin.users.index
	•	admin.users.create

---

3. 実装要件（Controllerで必ず守る）

3-1. Current を導入
	•	app/models/current.rb に CurrentAttributes を作る
	•	ApplicationController で Current.user と Current.tenant をセット
	•	ログイン未実装なので Current.user = User.first を使用（TODO コメントで差し替えポイントを明記）

3-2. Ability（権限判定サービス）
	•	app/services/ability.rb を作成
	•	Ability.new(Current.user).can?("admin.tenants.update") で判定できる
	•	user が nil の場合は必ず false

3-3. Admin::BaseController を導入して全管理画面を強制保護
	•	app/controllers/admin/base_controller.rb
	•	before_action :require_permission!
	•	権限キーは admin.#{controller_name}.#{action_name} で自動生成
	•	権限がない場合は 404（Not Found） で返す（情報漏洩しづらい）

3-4. テナント境界
	•	Admin配下の一覧/検索は必ず Current.tenant にスコープ
	•	例：Current.tenant.users / Current.tenant.roles のように取得

---

4. Viewでの出し分け（メニュー/ボタン）
	•	app/helpers/authorization_helper.rb を作り can?(key) ヘルパーを提供
	•	サイドバー・一覧の「編集/削除/作成」ボタンは can? で出し分け

---

5. 管理画面の対象リソース（最低限）

以下の管理画面を作成してください（雛形でOK）
	•	Tenants（index/show/edit/update）※ tenant は built_in 管理者のみ更新可能でも良い
	•	Roles（index/new/create/edit/update）＋ RoleにPermissionを付与するUI
	•	Users（index/new/create/edit/update）＋ UserにRoleを割り当てるUI

UI要件
	•	TailwindCSS 4.1 前提（クラスだけでOK）
	•	app/views/admin/shared/_sidebar.html.erb にサイドバーを分割
	•	app/views/admin/shared/_topbar.html.erb にトップバーを分割
	•	レイアウト app/views/layouts/admin.html.erb を作成
	•	メニューは can? で表示制御

---

6. Seed（超重要）

db/seeds.rb または db/seeds/permissions.rb のように分割して、以下を実装：
	•	permissions を上記規則で一括投入（例：resources × actions）
	•	built_in role（例：owner/admin）を作成し全権限付与
	•	User.first に owner を割り当て、仮ログインでも管理画面が見える状態にする

---

7. 実装の出力形式（必須）
	•	追加/変更するファイルを ファイルパス付きで列挙
	•	それぞれのファイルの 全文コード を提示
	•	必要な routes（namespace :admin）も提示
	•	既存モデルがある前提で、差分が分かるように「追加する関連」「追加カラム」「migration」も提示

---

8. 受け入れ条件（テスト観点）
	•	権限がない user に切り替えたとき、/admin 配下は 404 になる
	•	権限がある場合のみ、メニュー/ボタンが表示される
	•	他テナントの user/role が一覧に出ない

---

この指示に従い、Rails 8 のコードを生成してください。