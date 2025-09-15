class CreateApiKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :api_keys do |t|
      t.string :key
      t.string :name
      t.references :user, null: false, foreign_key: true
      t.json :scopes
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :api_keys, :key
    add_index :api_keys, :revoked_at
  end
end
