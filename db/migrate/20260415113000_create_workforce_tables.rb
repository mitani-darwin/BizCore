class CreateWorkforceTables < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :employee_code, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.string :employment_type, null: false, default: "hourly"
      t.date :joined_on
      t.decimal :base_hourly_wage, precision: 12, scale: 2, null: false, default: 0
      t.decimal :base_monthly_salary, precision: 14, scale: 2, null: false, default: 0
      t.decimal :overtime_rate_multiplier, precision: 5, scale: 2, null: false, default: 1.25
      t.integer :standard_daily_minutes, null: false, default: 480
      t.integer :default_break_minutes, null: false, default: 60
      t.decimal :paid_leave_granted_days, precision: 5, scale: 1, null: false, default: 10.0
      t.string :tel
      t.string :email
      t.text :note
      t.timestamps
    end
    add_index :employees, [:tenant_id, :employee_code], unique: true
    add_index :employees, [:tenant_id, :status]

    create_table :work_shifts do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.date :work_date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :break_minutes, null: false, default: 60
      t.string :status, null: false, default: "scheduled"
      t.text :note
      t.timestamps
    end
    add_index :work_shifts, [:tenant_id, :employee_id, :work_date], unique: true
    add_index :work_shifts, [:tenant_id, :work_date]

    create_table :attendance_records do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.references :work_shift, null: true, foreign_key: true
      t.date :work_date, null: false
      t.datetime :clock_in_at
      t.datetime :clock_out_at
      t.integer :break_minutes, null: false, default: 0
      t.integer :worked_minutes, null: false, default: 0
      t.integer :overtime_minutes, null: false, default: 0
      t.string :status, null: false, default: "draft"
      t.text :note
      t.timestamps
    end
    add_index :attendance_records, [:tenant_id, :employee_id, :work_date], unique: true
    add_index :attendance_records, [:tenant_id, :work_date]
    add_index :attendance_records, [:tenant_id, :status]

    create_table :leave_requests do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :days_count, precision: 5, scale: 1, null: false, default: 1.0
      t.string :leave_type, null: false, default: "paid_leave"
      t.string :status, null: false, default: "pending"
      t.text :reason
      t.text :note
      t.timestamps
    end
    add_index :leave_requests, [:tenant_id, :employee_id, :start_date]
    add_index :leave_requests, [:tenant_id, :status]

    create_table :payroll_runs do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :generated_by, null: true, foreign_key: { to_table: :users }
      t.string :run_number, null: false
      t.date :payroll_month, null: false
      t.string :status, null: false, default: "generated"
      t.datetime :generated_at
      t.decimal :total_gross_pay, precision: 14, scale: 2, null: false, default: 0
      t.integer :employee_count, null: false, default: 0
      t.text :note
      t.timestamps
    end
    add_index :payroll_runs, [:tenant_id, :payroll_month], unique: true
    add_index :payroll_runs, [:tenant_id, :run_number], unique: true

    create_table :payroll_entries do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :payroll_run, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.integer :worked_minutes, null: false, default: 0
      t.integer :overtime_minutes, null: false, default: 0
      t.decimal :paid_leave_days, precision: 5, scale: 1, null: false, default: 0
      t.decimal :base_pay, precision: 14, scale: 2, null: false, default: 0
      t.decimal :overtime_pay, precision: 14, scale: 2, null: false, default: 0
      t.decimal :paid_leave_pay, precision: 14, scale: 2, null: false, default: 0
      t.decimal :gross_pay, precision: 14, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :payroll_entries, [:payroll_run_id, :employee_id], unique: true
    add_index :payroll_entries, [:tenant_id, :employee_id]
  end
end
