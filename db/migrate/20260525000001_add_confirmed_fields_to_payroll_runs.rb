class AddConfirmedFieldsToPayrollRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :payroll_runs, :confirmed_at, :datetime
    add_column :payroll_runs, :confirmed_by_id, :integer
    add_index :payroll_runs, :confirmed_by_id
  end
end
