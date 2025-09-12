class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :type
      t.string :subtype
      t.references :family, null: false, foreign_key: true
      t.string :name
      t.bigint :balance, default: 0
      t.string :currency, default: "USD"

      t.timestamps
    end

    add_index :accounts, :type
  end
end
