class CreateTenantUserRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_user_roles, id: :bigint do |t|
      t.references :tenant_user, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.references :role, null: false, foreign_key: true, type: :bigint
      t.boolean :primary_flag, null: false, default: false
      t.timestamps
    end

    add_index :tenant_user_roles, [:tenant_user_id, :role_id], unique: true
  end
end
