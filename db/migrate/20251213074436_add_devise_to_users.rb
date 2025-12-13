class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
    end

    remove_column :users, :password_digest, :string

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
