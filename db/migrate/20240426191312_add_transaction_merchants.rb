class AddTransactionMerchants < ActiveRecord::Migration[7.2]
  def change
    create_table :transaction_merchants do |t|
      t.string "name", null: false
      t.string "color", default: "#e99537", null: false
      t.references :family, null: false, foreign_key: true

      t.timestamps
    end

    add_reference :transactions, :merchant, foreign_key: { to_table: :transaction_merchants }
  end
end
