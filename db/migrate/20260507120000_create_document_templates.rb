class CreateDocumentTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :document_templates do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :document_type, null: false
      t.text :settings

      t.timestamps
    end

    add_index :document_templates, [ :tenant_id, :document_type ], unique: true
  end
end
