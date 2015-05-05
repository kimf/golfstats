class AddFieldsToHolesMigration <  ActiveRecord::Migration
  def up
    add_column :holes, :index, :integer

    add_column :holes, :green_center_lat, :string
    add_column :holes, :green_center_lng, :string

    add_column :holes, :green_front_lat, :string
    add_column :holes, :green_front_lng, :string

    add_column :holes, :green_depth, :decimal

    remove_column :holes, :length

    create_table :tees do |t|
      t.integer :hole_id
      t.integer :slope_id
      t.integer :length
      t.string  :lat
      t.string  :lng

      t.timestamps
    end

    add_index :tees, [:hole_id, :slope_id]
  end

  def down
    add_column :holes, :length
    remove_column :holes, :index
    remove_column :holes, :green_center_lat
    remove_column :holes, :green_center_lng
    remove_column :holes, :green_front_lat
    remove_column :holes, :green_front_lng
    remove_column :holes, :green_depth
    drop_table :tees
  end
end
