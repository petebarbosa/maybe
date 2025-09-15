class CreateAccountVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :account_vehicles do |t|
      t.timestamps
    end
  end
end
