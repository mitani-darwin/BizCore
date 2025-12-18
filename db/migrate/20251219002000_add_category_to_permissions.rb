class AddCategoryToPermissions < ActiveRecord::Migration[8.1]
  def up
    add_column :permissions, :category, :string unless column_exists?(:permissions, :category)

    return unless column_exists?(:permissions, :category)

    execute <<~SQL.squish
      UPDATE permissions
         SET category = COALESCE(category, resource)
    SQL
  end

  def down
    remove_column :permissions, :category if column_exists?(:permissions, :category)
  end
end
