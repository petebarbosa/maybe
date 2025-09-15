class AddMetadataToSession < ActiveRecord::Migration[7.2]
  def change
    add_column :sessions, :data, :json, default: {}
  end
end
