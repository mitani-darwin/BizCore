class RemoveChangesFromAuditLogs < ActiveRecord::Migration[8.1]
  def up
    remove_column :audit_logs, :changes if column_exists?(:audit_logs, :changes)
  end

  def down
    add_column :audit_logs, :changes, metadata_column_type unless column_exists?(:audit_logs, :changes)
  end

  private

  def metadata_column_type
    adapter = connection.adapter_name.downcase
    adapter.include?("sqlite") ? :text : :jsonb
  end
end
