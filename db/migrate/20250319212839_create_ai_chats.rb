class CreateAiChats < ActiveRecord::Migration[7.2]
  def change
    create_table :chats do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :instructions
      t.json :error
      t.string :latest_assistant_response_id
      t.timestamps
    end

    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.string :type, null: false
      t.string :status, null: false, default: "complete"
      t.text :content
      t.string :ai_model
      t.timestamps

      # Developer message fields
      t.boolean :debug, default: false

      # Assistant message fields
      t.string :provider_id
      t.boolean :reasoning, default: false
    end

    create_table :tool_calls do |t|
      t.references :message, null: false, foreign_key: true
      t.string :provider_id, null: false
      t.string :provider_call_id
      t.string :type, null: false

      # Function specific fields
      t.string :function_name
      t.json :function_arguments
      t.json :function_result

      t.timestamps
    end

    add_reference :users, :last_viewed_chat, foreign_key: { to_table: :chats }, null: true
    add_column :users, :show_ai_sidebar, :boolean, default: true
    add_column :users, :ai_enabled, :boolean, default: false, null: false
  end
end
