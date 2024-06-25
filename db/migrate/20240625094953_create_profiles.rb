class CreateProfiles < ActiveRecord::Migration[6.1]
  def change
    create_table :profiles do |t|
      t.string :name, null: false, unique: true
      t.date :birthday, null: false
      t.string :phone_number, null:false, unique:true
      t.string :request_title, null:false
      t.text :request_description, null:false
      t.date :request_schedule, null:false

      t.timestamps
    end
  end
end
