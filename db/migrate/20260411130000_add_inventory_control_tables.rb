class AddInventoryControlTables < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_items, :safety_stock, :integer, null: false, default: 0

    create_table :stock_counts, id: :bigint do |t|
      t.references :tenant, null: false, foreign_key: true, index: true
      t.references :stock_item, null: false, foreign_key: true, index: true
      t.references :warehouse, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.integer :quantity_before, null: false
      t.integer :counted_quantity, null: false
      t.integer :adjustment_quantity, null: false, default: 0
      t.datetime :counted_at, null: false
      t.text :note
      t.timestamps
    end

    add_index :stock_counts, [:tenant_id, :counted_at]
  end
end
