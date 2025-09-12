class CreateTags < ActiveRecord::Migration[7.2]
  def change
    create_table :tags do |t|
      t.string :name
      t.string "color", default: "#e99537", null: false
      t.references :family, null: false, foreign_key: true
      t.timestamps
    end
  end
end
