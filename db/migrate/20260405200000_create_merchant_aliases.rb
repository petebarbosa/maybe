class CreateMerchantAliases < ActiveRecord::Migration[7.2]
  def change
    create_table :merchant_aliases do |t|
      t.references :family, type: :uuid, null: false, foreign_key: true
      t.references :merchant, null: false, foreign_key: true
      t.string :raw_name, null: false
      t.string :normalized_name, null: false
      t.string :source, null: false, default: "user_manual"

      t.timestamps
    end

    add_index :merchant_aliases, [ :family_id, :normalized_name ], unique: true, name: "index_merchant_aliases_on_family_and_normalized_name"
    add_index :merchant_aliases, [ :source ], name: "index_merchant_aliases_on_source"
  end
end
