class CreateProcurementTables < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :name_kana
      t.string :status, null: false, default: "active"
      t.string :postal_code
      t.string :address1
      t.string :address2
      t.string :tel
      t.string :email
      t.string :contact_person_department
      t.string :contact_person_name
      t.string :contact_person_email
      t.string :contact_person_tel
      t.integer :closing_day
      t.string :payment_due_rule
      t.string :payment_method
      t.text :note

      t.timestamps
    end

    add_index :suppliers, [ :tenant_id, :code ], unique: true
    add_index :suppliers, [ :tenant_id, :status ]

    create_table :purchase_orders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.string :purchase_order_number, null: false
      t.date :order_date, null: false
      t.date :requested_delivery_date
      t.string :ordered_by_name
      t.string :status, null: false, default: "draft"
      t.datetime :sent_at
      t.text :remarks

      t.timestamps
    end

    add_index :purchase_orders, [ :tenant_id, :purchase_order_number ], unique: true
    add_index :purchase_orders, [ :tenant_id, :status ]
    add_index :purchase_orders, [ :tenant_id, :order_date ]

    create_table :purchase_order_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :purchase_order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :line_no, null: false
      t.string :product_code_snapshot, null: false
      t.string :product_name_snapshot, null: false
      t.string :unit_name_snapshot, null: false
      t.string :tax_category_snapshot, null: false, default: "taxable_10"
      t.integer :quantity, null: false
      t.decimal :unit_cost, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.integer :received_quantity, null: false, default: 0
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :purchase_order_items, [ :purchase_order_id, :line_no ], unique: true

    create_table :purchase_receipts do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.references :purchase_order, null: false, foreign_key: true
      t.string :purchase_receipt_number, null: false
      t.date :received_on, null: false
      t.string :received_by_name
      t.string :status, null: false, default: "issued"
      t.text :remarks
      t.datetime :issued_at

      t.timestamps
    end

    add_index :purchase_receipts, [ :tenant_id, :purchase_receipt_number ], unique: true
    add_index :purchase_receipts, [ :tenant_id, :received_on ]

    create_table :purchase_receipt_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :purchase_receipt, null: false, foreign_key: true
      t.references :purchase_order_item, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :product_code_snapshot, null: false
      t.string :product_name_snapshot, null: false
      t.string :unit_name_snapshot, null: false
      t.integer :received_quantity, null: false
      t.decimal :unit_cost, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0

      t.timestamps
    end
  end
end
