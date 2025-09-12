class CreateAccountSyncs < ActiveRecord::Migration[7.2]
  def change
    create_table :account_syncs do |t|
      t.references :account, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.date :start_date
      t.datetime :last_ran_at
      t.string :error
      t.text :warnings, default: '[]'

      t.timestamps
    end

    remove_column :accounts, :status, :string
    remove_column :accounts, :sync_warnings, :json
    remove_column :accounts, :sync_errors, :json
  end
end
