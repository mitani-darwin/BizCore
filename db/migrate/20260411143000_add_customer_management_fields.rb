class AddCustomerManagementFields < ActiveRecord::Migration[8.1]
  def change
    add_column :customers, :status, :string, null: false, default: "active"
    add_column :customers, :contact_person_name, :string
    add_column :customers, :contact_person_department, :string
    add_column :customers, :contact_person_email, :string
    add_column :customers, :contact_person_tel, :string

    add_index :customers, [ :tenant_id, :status ]
  end
end
