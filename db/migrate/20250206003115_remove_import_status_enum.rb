class RemoveImportStatusEnum < ActiveRecord::Migration[7.2]
  def up
    change_column_default :imports, :status, nil
    change_column :imports, :status, :string
    # SQLite doesn't have types to drop
  end

  def down
    # SQLite doesn't support enums, just set default
    change_column_default :imports, :status, 'pending'
  end
end
