class AddLineIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :line_id, :string
    add_index :users, [:tenant_id, :line_id]
  end
end
