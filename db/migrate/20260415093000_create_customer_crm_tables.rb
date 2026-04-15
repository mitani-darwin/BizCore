class CreateCustomerCrmTables < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_inquiries do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :customer, null: true, foreign_key: true
      t.references :assigned_user, null: true, foreign_key: { to_table: :users }
      t.string :inquiry_number, null: false
      t.date :inquiry_date, null: false
      t.string :status, null: false, default: "new"
      t.string :source, null: false, default: "email"
      t.string :company_name
      t.string :contact_person_name
      t.string :contact_person_department
      t.string :contact_email
      t.string :contact_tel
      t.string :subject, null: false
      t.text :details
      t.date :response_due_date
      t.timestamps
    end
    add_index :customer_inquiries, [:tenant_id, :inquiry_number], unique: true
    add_index :customer_inquiries, [:tenant_id, :status]
    add_index :customer_inquiries, [:tenant_id, :inquiry_date]

    create_table :customer_opportunities do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :customer_inquiry, null: true, foreign_key: true
      t.references :assigned_user, null: true, foreign_key: { to_table: :users }
      t.string :opportunity_number, null: false
      t.date :opened_on, null: false
      t.date :expected_close_on
      t.date :closed_on
      t.string :stage, null: false, default: "hearing"
      t.string :subject, null: false
      t.decimal :expected_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :actual_sales_amount, precision: 14, scale: 2, null: false, default: 0
      t.integer :probability, null: false, default: 0
      t.text :summary
      t.text :next_action
      t.timestamps
    end
    add_index :customer_opportunities, [:tenant_id, :opportunity_number], unique: true
    add_index :customer_opportunities, [:tenant_id, :stage]
    add_index :customer_opportunities, [:tenant_id, :opened_on]
  end
end
