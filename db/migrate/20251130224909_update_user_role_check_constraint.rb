class UpdateUserRoleCheckConstraint < ActiveRecord::Migration[7.2]
  def change
    remove_check_constraint :users, name: "check_user_role"
    add_check_constraint :users, "role IN ('admin', 'member', 'super_admin')", name: "check_user_role"
  end
end
