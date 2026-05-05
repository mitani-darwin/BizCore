class CreatePurchaseAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :purchase_adjustments do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.references :purchase_order, null: false, foreign_key: true
      t.references :purchase_receipt, null: false, foreign_key: true
      t.references :purchase_receipt_item, foreign_key: true
      t.references :product, foreign_key: true
      t.string :adjustment_number, null: false
      t.string :adjustment_type, null: false
      t.date :adjustment_date, null: false
      t.string :status, null: false, default: "issued"
      t.string :product_code_snapshot
      t.string :product_name_snapshot
      t.string :unit_name_snapshot
      t.integer :quantity, null: false, default: 0
      t.decimal :unit_cost, precision: 14, scale: 2, null: false, default: 0
      t.decimal :amount, precision: 14, scale: 2, null: false, default: 0
      t.string :processed_by_name
      t.text :reason
      t.datetime :issued_at

      t.timestamps
    end

    add_index :purchase_adjustments, [ :tenant_id, :adjustment_number ], unique: true
    add_index :purchase_adjustments, [ :tenant_id, :adjustment_type ]
    add_index :purchase_adjustments, [ :tenant_id, :adjustment_date ]
  end
end
