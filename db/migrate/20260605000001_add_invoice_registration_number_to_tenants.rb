class AddInvoiceRegistrationNumberToTenants < ActiveRecord::Migration[8.1]
  def change
    add_column :tenants, :invoice_registration_number, :string
  end
end
