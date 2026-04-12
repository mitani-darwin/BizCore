class CreateQuotationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :quotations do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :quotation_number, null: false
      t.date :quotation_date, null: false
      t.date :expiration_date, null: false
      t.string :status, null: false, default: "draft"
      t.string :subject
      t.string :quoted_by_name
      t.text :remarks
      t.datetime :sent_at
      t.datetime :accepted_at
      t.datetime :converted_at

      t.timestamps
    end

    add_index :quotations, [:tenant_id, :quotation_number], unique: true
    add_index :quotations, [:tenant_id, :status]
    add_index :quotations, [:tenant_id, :quotation_date]

    create_table :quotation_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :quotation, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :line_no, null: false
      t.string :product_code_snapshot, null: false
      t.string :product_name_snapshot, null: false
      t.string :unit_name_snapshot, null: false
      t.string :tax_category_snapshot, null: false, default: "taxable_10"
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :quotation_items, [:quotation_id, :line_no], unique: true

    add_reference :orders, :quotation, foreign_key: true
  end
end
