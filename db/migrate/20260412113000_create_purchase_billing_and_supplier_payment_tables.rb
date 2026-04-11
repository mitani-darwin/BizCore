class CreatePurchaseBillingAndSupplierPaymentTables < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_bill_batches do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :executed_by, foreign_key: { to_table: :users }
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.string :batch_number, null: false
      t.date :closing_date, null: false
      t.date :billing_period_from, null: false
      t.date :billing_period_to, null: false
      t.date :bill_date, null: false
      t.date :default_due_date
      t.string :status, null: false, default: "issued"
      t.integer :bill_count, null: false, default: 0
      t.integer :supplier_count, null: false, default: 0
      t.decimal :total_amount, precision: 14, scale: 2, null: false, default: 0
      t.datetime :executed_at
      t.datetime :cancelled_at
      t.text :note

      t.timestamps
    end

    add_index :purchase_bill_batches, [:tenant_id, :batch_number], unique: true
    add_index :purchase_bill_batches, [:tenant_id, :closing_date]
    add_index :purchase_bill_batches, [:tenant_id, :billing_period_from, :billing_period_to]

    create_table :purchase_bills do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :purchase_bill_batch, foreign_key: true
      t.references :reissued_from, foreign_key: { to_table: :purchase_bills }
      t.string :bill_number, null: false
      t.date :closing_date, null: false
      t.date :billing_period_from, null: false
      t.date :billing_period_to, null: false
      t.date :bill_date, null: false
      t.date :due_date, null: false
      t.string :status, null: false, default: "issued"
      t.decimal :subtotal_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :tax_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :total_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :paid_amount, precision: 14, scale: 2, null: false, default: 0
      t.decimal :balance_amount, precision: 14, scale: 2, null: false, default: 0
      t.integer :closing_day_snapshot
      t.string :payment_due_rule_snapshot
      t.string :payment_method_snapshot
      t.datetime :cancelled_at
      t.text :remarks

      t.timestamps
    end

    add_index :purchase_bills, [:tenant_id, :bill_number], unique: true
    add_index :purchase_bills, [:tenant_id, :status]
    add_index :purchase_bills, [:tenant_id, :bill_date]

    create_table :purchase_bill_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :purchase_bill, null: false, foreign_key: true
      t.references :source, polymorphic: true
      t.string :description, null: false
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.string :tax_category, null: false, default: "taxable_10"

      t.timestamps
    end

    add_index :purchase_bill_items, [:tenant_id, :source_type, :source_id]

    create_table :supplier_payments do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.string :payment_number, null: false
      t.date :payment_date, null: false
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "pending"
      t.string :payment_method
      t.string :bank_name
      t.string :account_name
      t.string :reference_note

      t.timestamps
    end

    add_index :supplier_payments, [:tenant_id, :payment_number], unique: true
    add_index :supplier_payments, [:tenant_id, :payment_date]
    add_index :supplier_payments, [:tenant_id, :status]

    create_table :supplier_payment_allocations do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :supplier_payment, null: false, foreign_key: true
      t.references :purchase_bill, null: false, foreign_key: true
      t.decimal :allocated_amount, precision: 14, scale: 2, null: false, default: 0
      t.datetime :allocated_at

      t.timestamps
    end

    add_index :supplier_payment_allocations, [:supplier_payment_id, :purchase_bill_id], unique: true, name: "index_supplier_payment_allocations_on_payment_and_bill"
  end
end
