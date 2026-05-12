class CreateDailyReports < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_reports do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :site, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.date :report_date, null: false
      t.text :work_content, null: false
      t.decimal :work_hours, precision: 5, scale: 2, null: false
      t.text :notes

      t.timestamps
    end

    add_index :daily_reports, %i[tenant_id report_date]
    add_index :daily_reports, %i[tenant_id site_id]
    add_index :daily_reports, %i[tenant_id employee_id]
  end
end
