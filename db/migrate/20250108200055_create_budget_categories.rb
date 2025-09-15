class CreateBudgetCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :budget_categories do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.decimal :budgeted_spending, null: false, precision: 19, scale: 4
      t.string :currency, null: false
      t.timestamps
    end

    add_index :budget_categories, %i[budget_id category_id], unique: true
  end
end
