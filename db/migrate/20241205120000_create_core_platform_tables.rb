class CreateCorePlatformTables < ActiveRecord::Migration[8.1]
  def change
    create_table :tenants, id: :bigint do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :subdomain, null: false
      t.string :plan, null: false
      t.string :status, null: false
      t.string :billing_email, null: false
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :tenants, :code, unique: true
    add_index :tenants, :subdomain, unique: true

    create_table :users, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :time_zone
      t.string :locale
      t.boolean :is_owner, null: false, default: false
      t.datetime :last_sign_in_at
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :users, :tenant_id
    add_index :users, [:tenant_id, :email], unique: true

    create_table :roles, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :name, null: false
      t.string :key, null: false
      t.string :description
      t.boolean :built_in, null: false, default: false
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :roles, :tenant_id
    add_index :roles, [:tenant_id, :key], unique: true

    create_table :user_roles, id: :bigint do |t|
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.references :role, null: false, foreign_key: true, type: :bigint
      t.boolean :primary, null: false, default: false
      t.timestamps
    end

    add_index :user_roles, [:user_id, :role_id], unique: true

    create_table :permissions, id: :bigint do |t|
      t.string :key, null: false
      t.string :resource, null: false
      t.string :action, null: false
      t.string :name, null: false
      t.string :description
      t.timestamps
    end

    add_index :permissions, :key, unique: true

    create_table :role_permissions, id: :bigint do |t|
      t.references :role, null: false, foreign_key: true, type: :bigint
      t.references :permission, null: false, foreign_key: true, type: :bigint
      t.boolean :allowed, null: false, default: true
      t.timestamps
    end

    add_index :role_permissions, [:role_id, :permission_id], unique: true
  end
end
