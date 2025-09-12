class ConvertJsonToJsonb < ActiveRecord::Migration[7.2]
  def up
    # Convert all JSON columns to JSONB for better performance
    # SQLite 3.38+ supports JSONB which is more efficient than JSON

    # Accounts table
    change_column :accounts, :locked_attributes, :jsonb, default: {}

    # API Keys table
    change_column :api_keys, :scopes, :jsonb

    # Chats table
    change_column :chats, :error, :jsonb

    # Credit Cards table
    change_column :credit_cards, :locked_attributes, :jsonb, default: {}

    # Cryptos table
    change_column :cryptos, :locked_attributes, :jsonb, default: {}

    # Data Enrichments table
    change_column :data_enrichments, :value, :jsonb
    change_column :data_enrichments, :metadata, :jsonb

    # Depositories table
    change_column :depositories, :locked_attributes, :jsonb, default: {}

    # Entries table
    change_column :entries, :locked_attributes, :jsonb, default: {}

    # Imports table
    change_column :imports, :column_mappings, :jsonb

    # Investments table
    change_column :investments, :locked_attributes, :jsonb, default: {}

    # Loans table
    change_column :loans, :locked_attributes, :jsonb, default: {}

    # Other Assets table
    change_column :other_assets, :locked_attributes, :jsonb, default: {}

    # Other Liabilities table
    change_column :other_liabilities, :locked_attributes, :jsonb, default: {}

    # Plaid Accounts table
    change_column :plaid_accounts, :raw_payload, :jsonb, default: {}
    change_column :plaid_accounts, :raw_transactions_payload, :jsonb, default: {}
    change_column :plaid_accounts, :raw_investments_payload, :jsonb, default: {}
    change_column :plaid_accounts, :raw_liabilities_payload, :jsonb, default: {}

    # Plaid Items table
    change_column :plaid_items, :raw_payload, :jsonb, default: {}
    change_column :plaid_items, :raw_institution_payload, :jsonb, default: {}

    # Properties table
    change_column :properties, :locked_attributes, :jsonb, default: {}

    # Sessions table
    change_column :sessions, :prev_transaction_page_params, :jsonb, default: {}
    change_column :sessions, :data, :jsonb, default: {}

    # Syncs table
    change_column :syncs, :data, :jsonb

    # Tool Calls table
    change_column :tool_calls, :function_arguments, :jsonb
    change_column :tool_calls, :function_result, :jsonb

    # Trades table
    change_column :trades, :locked_attributes, :jsonb, default: {}

    # Transactions table
    change_column :transactions, :locked_attributes, :jsonb, default: {}

    # Valuations table
    change_column :valuations, :locked_attributes, :jsonb, default: {}

    # Vehicles table
    change_column :vehicles, :locked_attributes, :jsonb, default: {}
  end

  def down
    # Revert JSONB columns back to JSON

    # Accounts table
    change_column :accounts, :locked_attributes, :json, default: {}

    # API Keys table
    change_column :api_keys, :scopes, :json

    # Chats table
    change_column :chats, :error, :json

    # Credit Cards table
    change_column :credit_cards, :locked_attributes, :json, default: {}

    # Cryptos table
    change_column :cryptos, :locked_attributes, :json, default: {}

    # Data Enrichments table
    change_column :data_enrichments, :value, :json
    change_column :data_enrichments, :metadata, :json

    # Depositories table
    change_column :depositories, :locked_attributes, :json, default: {}

    # Entries table
    change_column :entries, :locked_attributes, :json, default: {}

    # Imports table
    change_column :imports, :column_mappings, :json

    # Investments table
    change_column :investments, :locked_attributes, :json, default: {}

    # Loans table
    change_column :loans, :locked_attributes, :json, default: {}

    # Other Assets table
    change_column :other_assets, :locked_attributes, :json, default: {}

    # Other Liabilities table
    change_column :other_liabilities, :locked_attributes, :json, default: {}

    # Plaid Accounts table
    change_column :plaid_accounts, :raw_payload, :json, default: {}
    change_column :plaid_accounts, :raw_transactions_payload, :json, default: {}
    change_column :plaid_accounts, :raw_investments_payload, :json, default: {}
    change_column :plaid_accounts, :raw_liabilities_payload, :json, default: {}

    # Plaid Items table
    change_column :plaid_items, :raw_payload, :json, default: {}
    change_column :plaid_items, :raw_institution_payload, :json, default: {}

    # Properties table
    change_column :properties, :locked_attributes, :json, default: {}

    # Sessions table
    change_column :sessions, :prev_transaction_page_params, :json, default: {}
    change_column :sessions, :data, :json, default: {}

    # Syncs table
    change_column :syncs, :data, :json

    # Tool Calls table
    change_column :tool_calls, :function_arguments, :json
    change_column :tool_calls, :function_result, :json

    # Trades table
    change_column :trades, :locked_attributes, :json, default: {}

    # Transactions table
    change_column :transactions, :locked_attributes, :json, default: {}

    # Valuations table
    change_column :valuations, :locked_attributes, :json, default: {}

    # Vehicles table
    change_column :vehicles, :locked_attributes, :json, default: {}
  end
end
