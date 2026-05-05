class CreateBillingBatchesAndEnhanceInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :billing_batches do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :executed_by, foreign_key: { to_table: :users }
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.string :batch_number, null: false
      t.date :closing_date, null: false
      t.date :billing_period_from, null: false
      t.date :billing_period_to, null: false
      t.date :invoice_date, null: false
      t.date :default_due_date
      t.string :status, null: false, default: "issued"
      t.integer :invoice_count, null: false, default: 0
      t.integer :customer_count, null: false, default: 0
      t.decimal :total_amount, precision: 14, scale: 2, null: false, default: 0
      t.datetime :executed_at
      t.datetime :cancelled_at
      t.text :note

      t.timestamps
    end

    add_index :billing_batches, [ :tenant_id, :batch_number ], unique: true
    add_index :billing_batches, [ :tenant_id, :closing_date ]
    add_index :billing_batches, [ :tenant_id, :billing_period_from, :billing_period_to ]

    change_table :invoices, bulk: true do |t|
      t.references :billing_batch, foreign_key: true
      t.references :reissued_from, foreign_key: { to_table: :invoices }
      t.integer :closing_day_snapshot
      t.string :payment_due_rule_snapshot
      t.string :invoice_delivery_method_snapshot
      t.datetime :cancelled_at
    end
  end
end
