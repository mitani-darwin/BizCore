class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.string :category, null: false, default: "construction"
      t.string :status, null: false, default: "active"
      t.integer :progress_percentage, null: false, default: 0
      t.text :description
      t.string :address
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    # テナント内でコードを一意にするインデックス
    add_index :sites, %i[tenant_id code], unique: true
    add_index :sites, %i[tenant_id status]
  end
end
