class UpdateAuditLogsForAdminBase < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:audit_logs)

    add_column :audit_logs, :actor_type, :string unless column_exists?(:audit_logs, :actor_type)
    add_column :audit_logs, :actor_id, :bigint unless column_exists?(:audit_logs, :actor_id)
    add_column :audit_logs, :action_key, :string unless column_exists?(:audit_logs, :action_key)
    add_column :audit_logs, :request_id, :string unless column_exists?(:audit_logs, :request_id)
    add_column :audit_logs, :path, :string unless column_exists?(:audit_logs, :path)
    add_column :audit_logs, :http_method, :string unless column_exists?(:audit_logs, :http_method)
    add_column :audit_logs, :status, :string, default: "succeeded", null: false unless column_exists?(:audit_logs, :status)
    add_column :audit_logs, :metadata, metadata_column_type unless column_exists?(:audit_logs, :metadata)

    backfill_new_columns

    remove_column :audit_logs, :changes if column_exists?(:audit_logs, :changes)

    change_column_null :audit_logs, :auditable_type, true if column_exists?(:audit_logs, :auditable_type)
    change_column_null :audit_logs, :auditable_id, true if column_exists?(:audit_logs, :auditable_id)
    change_column_null :audit_logs, :action_key, false if column_exists?(:audit_logs, :action_key)
    change_column_null :audit_logs, :action, true if column_exists?(:audit_logs, :action)
    change_column_null :audit_logs, :summary, true if column_exists?(:audit_logs, :summary)
    change_column_default :audit_logs, :status, from: nil, to: "succeeded" if column_exists?(:audit_logs, :status)

    add_index :audit_logs, [:actor_type, :actor_id] unless index_exists?(:audit_logs, [:actor_type, :actor_id])
    add_index :audit_logs, :action_key unless index_exists?(:audit_logs, :action_key)
    add_index :audit_logs, :request_id unless index_exists?(:audit_logs, :request_id)
  end

  def down
    return unless table_exists?(:audit_logs)

    remove_index :audit_logs, column: [:actor_type, :actor_id] if index_exists?(:audit_logs, [:actor_type, :actor_id])
    remove_index :audit_logs, column: :action_key if index_exists?(:audit_logs, :action_key)
    remove_index :audit_logs, column: :request_id if index_exists?(:audit_logs, :request_id)

    add_column :audit_logs, :changes, :json unless column_exists?(:audit_logs, :changes)
    remove_column :audit_logs, :metadata if column_exists?(:audit_logs, :metadata)
    remove_column :audit_logs, :status if column_exists?(:audit_logs, :status)
    remove_column :audit_logs, :http_method if column_exists?(:audit_logs, :http_method)
    remove_column :audit_logs, :path if column_exists?(:audit_logs, :path)
    remove_column :audit_logs, :request_id if column_exists?(:audit_logs, :request_id)
    remove_column :audit_logs, :action_key if column_exists?(:audit_logs, :action_key)
    remove_column :audit_logs, :actor_id if column_exists?(:audit_logs, :actor_id)
    remove_column :audit_logs, :actor_type if column_exists?(:audit_logs, :actor_type)

    change_column_null :audit_logs, :auditable_type, false if column_exists?(:audit_logs, :auditable_type)
    change_column_null :audit_logs, :auditable_id, false if column_exists?(:audit_logs, :auditable_id)
    change_column_null :audit_logs, :action, false if column_exists?(:audit_logs, :action)
    change_column_null :audit_logs, :summary, false if column_exists?(:audit_logs, :summary)
  end

  private

  def metadata_column_type
    adapter = connection.adapter_name.downcase
    adapter.include?("sqlite") ? :text : :jsonb
  end

  def backfill_new_columns
    return unless column_exists?(:audit_logs, :action)

    execute <<~SQL.squish
      UPDATE audit_logs
         SET action_key = COALESCE(action_key, action, 'unknown'),
             actor_type = COALESCE(actor_type, CASE WHEN user_id IS NOT NULL THEN 'User' ELSE NULL END),
             actor_id = COALESCE(actor_id, user_id),
             status = COALESCE(status, 'succeeded')
    SQL
  end
end
