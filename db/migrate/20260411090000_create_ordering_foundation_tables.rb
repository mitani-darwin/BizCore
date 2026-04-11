class CreateOrderingFoundationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :customers, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :code, null: false
      t.string :name, null: false
      t.string :name_kana
      t.string :postal_code
      t.string :address1
      t.string :address2
      t.string :tel
      t.string :email
      t.integer :closing_day
      t.string :payment_due_rule
      t.string :payment_method
      t.string :invoice_delivery_method
      t.text :note
      t.timestamps
    end
    add_index :customers, [:tenant_id, :code], unique: true

    create_table :products, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :code, null: false
      t.string :name, null: false
      t.string :unit_name, null: false
      t.decimal :standard_price, precision: 14, scale: 2, null: false, default: 0
      t.string :tax_category, null: false, default: "taxable_10"
      t.boolean :active, null: false, default: true
      t.text :note
      t.timestamps
    end
    add_index :products, [:tenant_id, :code], unique: true

    create_table :warehouses, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :warehouses, [:tenant_id, :code], unique: true

    create_table :stock_items, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :warehouse, null: false, foreign_key: true, type: :bigint
      t.references :product, null: false, foreign_key: true, type: :bigint
      t.integer :quantity_on_hand, null: false, default: 0
      t.integer :quantity_reserved, null: false, default: 0
      t.timestamps
    end
    add_index :stock_items, [:tenant_id, :warehouse_id, :product_id], unique: true

    create_table :stock_movements, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :warehouse, null: false, foreign_key: true, type: :bigint
      t.references :product, null: false, foreign_key: true, type: :bigint
      t.string :movement_type, null: false
      t.integer :quantity, null: false
      t.date :occurred_on, null: false
      t.references :reference, polymorphic: true, type: :bigint
      t.text :note
      t.timestamps
    end
    add_index :stock_movements, [:tenant_id, :occurred_on]

    create_table :orders, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :order_number, null: false
      t.references :customer, null: false, foreign_key: true, type: :bigint
      t.date :order_date, null: false
      t.date :requested_delivery_date
      t.string :status, null: false, default: "draft"
      t.string :ordered_by_name
      t.string :delivery_address
      t.text :remarks
      t.datetime :sent_at
      t.datetime :accepted_at
      t.timestamps
    end
    add_index :orders, [:tenant_id, :order_number], unique: true

    create_table :order_items, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :order, null: false, foreign_key: true, type: :bigint
      t.integer :line_no, null: false
      t.references :product, null: false, foreign_key: true, type: :bigint
      t.string :product_code_snapshot, null: false
      t.string :product_name_snapshot, null: false
      t.string :unit_name_snapshot, null: false
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.string :tax_category_snapshot, null: false, default: "taxable_10"
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :order_items, [:order_id, :line_no], unique: true

    create_table :stock_allocations, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :order_item, null: false, foreign_key: true, type: :bigint
      t.references :warehouse, null: false, foreign_key: true, type: :bigint
      t.references :product, null: false, foreign_key: true, type: :bigint
      t.integer :allocated_quantity, null: false
      t.string :status, null: false, default: "reserved"
      t.datetime :allocated_at, null: false
      t.datetime :released_at
      t.timestamps
    end
    add_index :stock_allocations, [:tenant_id, :order_item_id]

    create_table :deliveries, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :delivery_number, null: false
      t.references :order, null: false, foreign_key: true, type: :bigint
      t.references :customer, null: false, foreign_key: true, type: :bigint
      t.date :delivery_date, null: false
      t.string :status, null: false, default: "issued"
      t.string :delivery_address
      t.text :remarks
      t.datetime :issued_at
      t.timestamps
    end
    add_index :deliveries, [:tenant_id, :delivery_number], unique: true

    create_table :delivery_items, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :delivery, null: false, foreign_key: true, type: :bigint
      t.references :order_item, null: false, foreign_key: true, type: :bigint
      t.references :product, null: false, foreign_key: true, type: :bigint
      t.string :product_code_snapshot, null: false
      t.string :product_name_snapshot, null: false
      t.string :unit_name_snapshot, null: false
      t.integer :delivered_quantity, null: false
      t.decimal :unit_price, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.timestamps
    end

    create_table :invoices, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :invoice_number, null: false
      t.references :customer, null: false, foreign_key: true, type: :bigint
      t.date :closing_date, null: false
      t.date :billing_period_from, null: false
      t.date :billing_period_to, null: false
      t.date :invoice_date, null: false
      t.date :due_date, null: false
      t.string :status, null: false, default: "issued"
      t.decimal :subtotal_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :tax_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :total_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :paid_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :balance_amount, precision: 14, scale: 2, null: false, default: 0
      t.text :remarks
      t.timestamps
    end
    add_index :invoices, [:tenant_id, :invoice_number], unique: true

    create_table :invoice_items, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :invoice, null: false, foreign_key: true, type: :bigint
      t.references :source, polymorphic: true, type: :bigint
      t.string :description, null: false
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.string :tax_category, null: false, default: "taxable_10"
      t.timestamps
    end
    add_index :invoice_items, [:tenant_id, :source_type, :source_id], name: "index_invoice_items_on_tenant_and_source"

    create_table :payments, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.string :payment_number, null: false
      t.references :customer, null: false, foreign_key: true, type: :bigint
      t.date :payment_date, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.string :payment_method
      t.string :bank_name
      t.string :account_name
      t.string :reference_note
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :payments, [:tenant_id, :payment_number], unique: true

    create_table :payment_allocations, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, type: :bigint
      t.references :payment, null: false, foreign_key: true, type: :bigint
      t.references :invoice, null: false, foreign_key: true, type: :bigint
      t.decimal :allocated_amount, precision: 14, scale: 2, null: false, default: 0
      t.datetime :allocated_at, null: false
      t.timestamps
    end
    add_index :payment_allocations, [:payment_id, :invoice_id], unique: true
  end
end
