# マルチテナント基盤 ER 図（業務系テーブルなし）

この図は、SaaS の根幹となる **テナント・ユーザー・ロール・権限（RBAC）** のみで構成される  
「マルチテナント基盤」部分の ER 図です。

業務系（顧客・見積・請求・商品・タグ・メモ・添付・通知…）は含めず、  
マルチテナントを成立させるための **最小構成のコアレイヤー** を表します。

```mermaid
erDiagram

  TENANTS {
    bigint id PK
    string name
    string code
    string subdomain
    string plan
    string status
    string billing_email
    datetime deleted_at
    datetime created_at
    datetime updated_at
  }

  USERS {
    bigint id PK
    bigint tenant_id FK
    string name
    string email
    string password_digest
    string time_zone
    string locale
    boolean is_owner
    datetime last_sign_in_at
    datetime deleted_at
    datetime created_at
    datetime updated_at
  }

  ROLES {
    bigint id PK
    bigint tenant_id FK
    string name
    string key
    string description
    boolean built_in
    datetime deleted_at
    datetime created_at
    datetime updated_at
  }

  USER_ROLES {
    bigint id PK
    bigint user_id FK
    bigint role_id FK
    boolean primary
    datetime created_at
    datetime updated_at
  }

  PERMISSIONS {
    bigint id PK
    string key
    string resource
    string action
    string name
    string description
    datetime created_at
    datetime updated_at
  }

  ROLE_PERMISSIONS {
    bigint id PK
    bigint role_id FK
    bigint permission_id FK
    boolean allowed
    datetime created_at
    datetime updated_at
  }

  %% マルチテナント構造
  TENANTS ||--o{ USERS : has_many
  TENANTS ||--o{ ROLES : has_many

  %% RBAC（認可）
  USERS ||--o{ USER_ROLES : has_many
  ROLES ||--o{ USER_ROLES : has_many

  ROLES ||--o{ ROLE_PERMISSIONS : has_many
  PERMISSIONS ||--o{ ROLE_PERMISSIONS : has_many