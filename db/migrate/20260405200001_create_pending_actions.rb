class CreatePendingActions < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_actions, id: :uuid do |t|
      t.string :action_type, null: false
      t.jsonb :params, null: false, default: {}
      t.jsonb :preview, null: false, default: {}
      t.uuid :family_id, null: false
      t.uuid :user_id
      t.datetime :expires_at, null: false
      t.datetime :confirmed_at
      t.string :confirmed_by
      t.jsonb :audit_result

      t.timestamps
    end

    add_index :pending_actions, :expires_at
    add_index :pending_actions, %i[family_id action_type]
  end
end
