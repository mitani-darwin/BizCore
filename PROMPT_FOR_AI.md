---

🔷 プロジェクト概要

本プロジェクトは 日本の中小企業向け共通業務基盤 SaaS を構築するものである。
Rails 8 を利用し、論理マルチテナント方式 と ロールベースの認可（RBAC） を採用する。

AI が生成するコード／解説／設計は、必ず本ドキュメントのルールに従うこと。

---

🔷 技術スタック
	•	Ruby on Rails 8（Importmap / Vite どちらも可）
	•	DB：開発 SQLite3、商用 PostgreSQL
	•	マルチテナント：各テーブルに tenant_id を持つ（認証系以外）
	•	認証：Rails 標準（has_secure_password）または bcrypt
	•	権限：ロールベース（Role — Permission — User）

---

🔷 命名規約（最重要）

AI は以下の命名規約を厳密に守ること。

テーブル名
	•	snake_case の 複数形
	•	主キーはすべて id

外部キー
	•	xxx_id（例：tenant_id, customer_id）

タイムスタンプ
	•	created_at, updated_at を必ず追加
	•	論理削除が必要なテーブルは deleted_at を追加（NULL = active）

モデル名
	•	単数形（例：Tenant, User）

---

🔷 マルチテナント規約

AI はコードを生成するとき、以下を必ず考慮する。

▸ 1. 業務テーブルは必ず tenant_id を持つ

ただし認証系（permissions, role_permissions 等）は除く。

▸ 2. コントローラのスコープ

AI は以下のようなスコープ例を使用すること：
```
current_tenant.customers
```
または
```
Customer.where(tenant_id: current_tenant.id)
```

▸ 3. テナント越えアクセスは禁止

AI は安全なクエリを書くこと。

---

🔷 権限（RBAC）規約

AI は以下の ER 図に基づいて role / permission を扱う。
```
erDiagram

  TENANTS ||--o{ USERS : has_many
  TENANTS ||--o{ ROLES : has_many

  USERS ||--o{ USER_ROLES : has_many
  ROLES ||--o{ USER_ROLES : has_many

  ROLES ||--o{ ROLE_PERMISSIONS : has_many
  PERMISSIONS ||--o{ ROLE_PERMISSIONS : has_many
```

ユーザーの権限判定

AI がコードを書くときは、以下のようなメソッドを前提にする：
```
def can?(permission_key)
  permissions.exists?(key: permission_key)
end
```

---

🔷 ディレクトリ構造（AI の出力ルール）

AI は Rails 標準構造に従うこと。
```
app/
  models/
  controllers/
  views/
  services/
  presenters/
  helpers/
  policies/
db/
  migrations/
docs/
  diagrams/
config/
  routes.rb
PROMPT_FOR_AI.md  ← このファイル
```

---

🔷 ER 図（基盤ドメイン：テナント・認証・権限）


---

🔷 AI に期待するコード生成パターン

AI は以下のようなコード生成を行うべき。

---

1. モデル生成例（User）

```
class User < ApplicationRecord
  belongs_to :tenant
  has_secure_password

  has_many :user_roles
  has_many :roles, through: :user_roles

  has_many :role_permissions, through: :roles
  has_many :permissions, through: :role_permissions

  validates :name, :email, presence: true
  validates :email, uniqueness: { scope: :tenant_id }

  def can?(permission_key)
    permissions.exists?(key: permission_key)
  end
end
```

---

2. マイグレーション生成ルール

AI が生成するマイグレーションは以下に従う：
	•	PK は id: :bigint
	•	外部キーには index をつける
	•	業務テーブルは tenant_id を必ず含める

例：
```
create_table :customers, id: :bigint do |t|
  t.bigint :tenant_id, null: false
  t.string :name, null: false
  t.string :email
  t.datetime :deleted_at
  t.timestamps
end

add_index :customers, :tenant_id
```

---

3. コントローラ生成ルール

AI は index アクションをこの形で書く：
```
def index
  @customers = current_tenant.customers.order(created_at: :desc)
end
```

---

4. ルーティング生成ルール

AI は RESTful を基本とし、ネストよりスコープ方式を推奨：
```
scope module: :tenant do
  resources :customers
  resources :invoices
end
```

---

5. 画面生成ルール

AI は TailwindCSS を使用する前提で HTML も記述する。

---

🔷 AI 出力の禁止事項

AI は以下を絶対にやらないこと：
	•	テーブル名を勝手に変える
	•	カラム名を変える
	•	ER 図にないリレーションを追加する
	•	マルチテナントを無視したデータ取得
	•	tenant_id をつけ忘れる（認証テーブルを除く）

---

🔷 AI への最終命令（最重要）

あなた（AI）は、この PROMPT_FOR_AI.md に従ってコードを生成し、設計し、修正しなければならない。

この仕様書より優先されるルールは存在しない。

---

🔷 プロジェクト概要

本プロジェクトは 日本の中小企業向け共通業務基盤 SaaS を構築するものである。
Rails 8 を利用し、論理マルチテナント方式 と ロールベースの認可（RBAC） を採用する。

AI が生成するコード／解説／設計は、必ず本ドキュメントのルールに従うこと。

---

🔷 技術スタック
	•	Ruby on Rails 8（Importmap / Vite どちらも可）
	•	DB：開発 SQLite3、商用 PostgreSQL
	•	マルチテナント：各テーブルに tenant_id を持つ（認証系以外）
	•	認証：Rails 標準（has_secure_password）または bcrypt
	•	権限：ロールベース（Role — Permission — User）

---

🔷 命名規約（最重要）

AI は以下の命名規約を厳密に守ること。

テーブル名
	•	snake_case の 複数形
	•	主キーはすべて id

外部キー
	•	xxx_id（例：tenant_id, customer_id）

タイムスタンプ
	•	created_at, updated_at を必ず追加
	•	論理削除が必要なテーブルは deleted_at を追加（NULL = active）

モデル名
	•	単数形（例：Tenant, User）

---

🔷 マルチテナント規約

AI はコードを生成するとき、以下を必ず考慮する。

▸ 1. 業務テーブルは必ず tenant_id を持つ

ただし認証系（permissions, role_permissions 等）は除く。

▸ 2. コントローラのスコープ

AI は以下のようなスコープ例を使用すること：
```
current_tenant.customers
```
または
```
Customer.where(tenant_id: current_tenant.id)
```

▸ 3. テナント越えアクセスは禁止

AI は安全なクエリを書くこと。

---

🔷 権限（RBAC）規約

AI は以下の ER 図に基づいて role / permission を扱う。
```
erDiagram

  TENANTS ||--o{ USERS : has_many
  TENANTS ||--o{ ROLES : has_many

  USERS ||--o{ USER_ROLES : has_many
  ROLES ||--o{ USER_ROLES : has_many

  ROLES ||--o{ ROLE_PERMISSIONS : has_many
  PERMISSIONS ||--o{ ROLE_PERMISSIONS : has_many
```

ユーザーの権限判定

AI がコードを書くときは、以下のようなメソッドを前提にする：
```
def can?(permission_key)
  permissions.exists?(key: permission_key)
end
```

---

🔷 ディレクトリ構造（AI の出力ルール）

AI は Rails 標準構造に従うこと。
```
app/
  models/
  controllers/
  views/
  services/
  presenters/
  helpers/
  policies/
db/
  migrations/
docs/
  diagrams/
config/
  routes.rb
PROMPT_FOR_AI.md  ← このファイル
```

---

🔷 ER 図（基盤ドメイン：テナント・認証・権限）


---

🔷 AI に期待するコード生成パターン

AI は以下のようなコード生成を行うべき。

---

1. モデル生成例（User）

```
class User < ApplicationRecord
  belongs_to :tenant
  has_secure_password

  has_many :user_roles
  has_many :roles, through: :user_roles

  has_many :role_permissions, through: :roles
  has_many :permissions, through: :role_permissions

  validates :name, :email, presence: true
  validates :email, uniqueness: { scope: :tenant_id }

  def can?(permission_key)
    permissions.exists?(key: permission_key)
  end
end
```

---

2. マイグレーション生成ルール

AI が生成するマイグレーションは以下に従う：
	•	PK は id: :bigint
	•	外部キーには index をつける
	•	業務テーブルは tenant_id を必ず含める

例：
```
create_table :customers, id: :bigint do |t|
  t.bigint :tenant_id, null: false
  t.string :name, null: false
  t.string :email
  t.datetime :deleted_at
  t.timestamps
end

add_index :customers, :tenant_id
```

---

3. コントローラ生成ルール

AI は index アクションをこの形で書く：
```
def index
  @customers = current_tenant.customers.order(created_at: :desc)
end
```

---

4. ルーティング生成ルール

AI は RESTful を基本とし、ネストよりスコープ方式を推奨：
```
scope module: :tenant do
  resources :customers
  resources :invoices
end
```

---

5. 画面生成ルール

AI は TailwindCSS を使用する前提で HTML も記述する。

---

🔷 AI 出力の禁止事項

AI は以下を絶対にやらないこと：
	•	テーブル名を勝手に変える
	•	カラム名を変える
	•	ER 図にないリレーションを追加する
	•	マルチテナントを無視したデータ取得
	•	tenant_id をつけ忘れる（認証テーブルを除く）

---

🔷 AI への最終命令（最重要）

あなた（AI）は、この PROMPT_FOR_AI.md に従ってコードを生成し、設計し、修正しなければならない。

この仕様書より優先されるルールは存在しない。

