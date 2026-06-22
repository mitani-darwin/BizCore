class AddIndustryToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :industry, :string, default: "general", null: false
  end
end
