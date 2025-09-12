class AddRoleToUsers < ActiveRecord::Migration[7.2]
  def change
    # SQLite doesn't support enums, use string with check constraint
    add_column :users, :role, :string, default: "member", null: false
    add_check_constraint :users, "role IN ('admin', 'member')", name: "check_user_role"
  end
end
