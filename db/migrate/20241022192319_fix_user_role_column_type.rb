class FixUserRoleColumnType < ActiveRecord::Migration[7.2]
  def change
    # SQLite doesn't need type conversion, just ensure default is set
    change_column_default :users, :role, 'member'
  end
end
