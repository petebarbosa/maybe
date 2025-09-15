class AddDataEnrichments < ActiveRecord::Migration[7.2]
  def change
    create_table :data_enrichments do |t|
      t.references :enrichable, polymorphic: true, null: false
      t.string :source
      t.string :attribute_name
      t.json :value
      t.json :metadata

      t.timestamps
    end

    add_index :data_enrichments, [ :enrichable_id, :enrichable_type, :source, :attribute_name ], unique: true

    # Entries
    add_column :entries, :locked_attributes, :json, default: {}
    add_column :transactions, :locked_attributes, :json, default: {}
    add_column :trades, :locked_attributes, :json, default: {}
    add_column :valuations, :locked_attributes, :json, default: {}

    # Accounts
    add_column :accounts, :locked_attributes, :json, default: {}
    add_column :depositories, :locked_attributes, :json, default: {}
    add_column :investments, :locked_attributes, :json, default: {}
    add_column :cryptos, :locked_attributes, :json, default: {}
    add_column :properties, :locked_attributes, :json, default: {}
    add_column :vehicles, :locked_attributes, :json, default: {}
    add_column :other_assets, :locked_attributes, :json, default: {}
    add_column :credit_cards, :locked_attributes, :json, default: {}
    add_column :loans, :locked_attributes, :json, default: {}
    add_column :other_liabilities, :locked_attributes, :json, default: {}
  end
end
