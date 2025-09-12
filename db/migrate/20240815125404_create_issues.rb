class CreateIssues < ActiveRecord::Migration[7.2]
  def change
    create_table :issues do |t|
      t.references :issuable, polymorphic: true
      t.string :type
      t.integer :severity
      t.datetime :last_observed_at
      t.datetime :resolved_at
      t.json :data

      t.timestamps
    end
  end
end
