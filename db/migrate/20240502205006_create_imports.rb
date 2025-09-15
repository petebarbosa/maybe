class CreateImports < ActiveRecord::Migration[7.2]
  def change
    # create_enum :import_status, %w[pending importing complete failed]

    create_table :imports do |t|
      t.references :account, null: false, foreign_key: true
      t.json :column_mappings
      t.string :status, default: "pending"
      t.string :raw_csv_str
      t.string :normalized_csv_str

      t.timestamps
    end
  end
end
