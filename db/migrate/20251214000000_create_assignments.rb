class CreateAssignments < ActiveRecord::Migration[8.1]
  def up
    create_table :assignments, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :user, null: false, foreign_key: true, type: :bigint
      t.references :role, null: false, foreign_key: true, type: :bigint
      t.timestamps
    end

    add_index :assignments, [:tenant_id, :user_id, :role_id], unique: true

    if table_exists?(:user_roles)
      execute <<~SQL.squish
        INSERT INTO assignments (tenant_id, user_id, role_id, created_at, updated_at)
        SELECT users.tenant_id, user_roles.user_id, user_roles.role_id,
               COALESCE(user_roles.created_at, CURRENT_TIMESTAMP),
               COALESCE(user_roles.updated_at, CURRENT_TIMESTAMP)
        FROM user_roles
        INNER JOIN users ON users.id = user_roles.user_id
      SQL
    end
  end

  def down
    drop_table :assignments
  end
end
