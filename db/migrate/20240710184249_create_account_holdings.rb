class CreateAccountHoldings < ActiveRecord::Migration[7.2]
  def change
    create_table :account_holdings do |t|
      t.references :account, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true
      t.date :date
      t.decimal :qty, precision: 19, scale: 4
      t.decimal :price, precision: 19, scale: 4
      t.decimal :amount, precision: 19, scale: 4
      t.string :currency

      t.timestamps
    end

    add_index :account_holdings, %i[account_id security_id date currency], unique: true
  end
end
