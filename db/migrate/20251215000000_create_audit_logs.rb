class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :user, null: true, foreign_key: true, type: :bigint
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.string :summary, null: false
      t.json :changes
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :created_at
  end
end
