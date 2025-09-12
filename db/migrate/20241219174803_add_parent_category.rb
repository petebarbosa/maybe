class AddParentCategory < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :parent_id, :string
    remove_column :categories, :internal_category, :string
  end
end
