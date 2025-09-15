class CreateAccountLoans < ActiveRecord::Migration[7.2]
  def change
    create_table :account_loans do |t|
      t.timestamps
    end
  end
end
