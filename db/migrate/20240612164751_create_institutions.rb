class CreateInstitutions < ActiveRecord::Migration[7.2]
  def change
    create_table :institutions do |t|
      t.string :name, null: false
      t.string :logo_url
      t.references :family, null: false, foreign_key: true

      t.timestamps
    end
  end
end
