class AddSyncStatusFieldsToAccount < ActiveRecord::Migration[7.2]
  def change
    # SQLite doesn't support enums, use string instead
    remove_column :accounts, :status, :string

    change_table :accounts do |t|
      t.string :status, default: "ok", null: false
      t.json :sync_warnings, default: '[]', null: false
      t.json :sync_errors, default: '[]', null: false
    end
  end
end
