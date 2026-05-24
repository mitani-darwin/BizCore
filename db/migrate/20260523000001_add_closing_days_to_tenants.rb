class AddClosingDaysToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :billing_closing_day, :integer
    add_column :tenants, :payroll_closing_day, :integer
    add_column :tenants, :purchase_closing_day, :integer
  end
end
