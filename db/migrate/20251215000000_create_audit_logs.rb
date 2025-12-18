class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :actor, polymorphic: true, type: :bigint
      t.string :action_key, null: false
      t.references :auditable, polymorphic: true, type: :bigint
      t.string :request_id
      t.string :ip_address
      t.string :user_agent
      t.string :path
      t.string :http_method
      t.string :status, null: false, default: "succeeded"
      t.send(metadata_column_type, :metadata)
      t.timestamps
    end

    add_index :audit_logs, :action_key
    add_index :audit_logs, :request_id
  end

  private

  def metadata_column_type
    adapter = connection.adapter_name.downcase
    adapter.include?("sqlite") ? :text : :jsonb
  end
end
