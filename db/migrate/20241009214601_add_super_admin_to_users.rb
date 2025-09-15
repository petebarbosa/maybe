class AddSuperAdminToUsers < ActiveRecord::Migration[7.2]
  def change
    # SQLite doesn't have types to drop, just ensure column is string
    change_column :users, :role, :string, default: 'member'
  end
end
