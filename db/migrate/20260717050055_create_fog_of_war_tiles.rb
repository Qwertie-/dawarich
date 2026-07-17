class CreateFogOfWarTiles < ActiveRecord::Migration[8.1]
  def change
    create_table :fog_of_war_tiles do |t|
      t.timestamps
      t.references :user, null: false, foreign_key: true
      t.string :h3_index, null: false
      t.index [:user_id, :h3_index], unique: true
    end

    add_column :points, :fog_of_war_calculated_at, :datetime
  end
end
