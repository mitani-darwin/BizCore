class CreateExpenseReports < ActiveRecord::Migration[8.1]
  def change
    create_table :expense_reports do |t|
      t.bigint :tenant_id, null: false
      t.bigint :employee_id, null: false
      t.date :expensed_on, null: false
      t.string :category, null: false, default: "other"
      t.text :description, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.text :purpose
      t.text :note
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :expense_reports, :tenant_id
    add_index :expense_reports, :employee_id
    add_index :expense_reports, [ :tenant_id, :status ]
    add_index :expense_reports, [ :tenant_id, :employee_id, :expensed_on ],
              name: "idx_expense_reports_on_tenant_employee_date"
    add_foreign_key :expense_reports, :tenants
    add_foreign_key :expense_reports, :employees
  end
end
