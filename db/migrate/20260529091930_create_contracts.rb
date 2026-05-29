class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts do |t|
      t.bigint  :tenant_id,        null: false
      t.bigint  :customer_id
      t.bigint  :supplier_id
      t.string  :contract_number,  null: false
      t.string  :title,            null: false
      t.string  :counterparty_type, null: false, default: "other"
      t.string  :status,           null: false, default: "draft"
      t.date    :started_on,       null: false
      t.date    :ended_on
      t.boolean :auto_renewal,     null: false, default: false
      t.decimal :amount,           precision: 14, scale: 2
      t.text    :description
      t.text    :note
      t.timestamps
    end

    add_index :contracts, :tenant_id
    add_index :contracts, :customer_id
    add_index :contracts, :supplier_id
    add_index :contracts, [ :tenant_id, :contract_number ], unique: true
    add_index :contracts, [ :tenant_id, :status ]
    add_index :contracts, [ :tenant_id, :ended_on ]
    add_foreign_key :contracts, :tenants
    add_foreign_key :contracts, :customers
    add_foreign_key :contracts, :suppliers
  end
end
