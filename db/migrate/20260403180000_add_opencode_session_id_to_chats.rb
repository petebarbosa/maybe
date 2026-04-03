class AddOpencodeSessionIdToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :opencode_session_id, :string
  end
end
