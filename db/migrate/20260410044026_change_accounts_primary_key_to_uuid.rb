class ChangeAccountsPrimaryKeyToUuid < ActiveRecord::Migration[8.1]
  def up
    # Step 1: Store old bigint IDs and create UUID mapping
    add_column :accounts, :old_id, :bigint
    execute "UPDATE accounts SET old_id = id"

    # Step 2: Create a new UUID column in accounts
    add_column :accounts, :uuid_id, :uuid, default: -> { "gen_random_uuid()" }

    # Step 3: Remove foreign key constraint
    remove_foreign_key :entries, :accounts

    # Step 4: Change accounts primary key to UUID
    execute "ALTER TABLE accounts DROP CONSTRAINT accounts_pkey CASCADE"
    remove_column :accounts, :id
    rename_column :accounts, :uuid_id, :id
    execute "ALTER TABLE accounts ADD PRIMARY KEY (id)"

    # Step 5: Update entries with new UUID based on old_id mapping
    add_column :entries, :uuid_account_id, :uuid

    execute <<~SQL
      UPDATE entries#{' '}
      SET uuid_account_id = accounts.id#{' '}
      FROM accounts#{' '}
      WHERE entries.account_id = accounts.old_id
    SQL

    # Step 6: Clean up old columns and rename
    remove_column :entries, :account_id
    rename_column :entries, :uuid_account_id, :account_id
    remove_column :accounts, :old_id

    # Step 7: Add foreign key back
    add_foreign_key :entries, :accounts, column: :account_id

    # Note: Indexes are automatically recreated by the CASCADE from the primary key constraint
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
