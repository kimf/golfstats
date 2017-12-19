class AddNewPosFieldsMigration <  ActiveRecord::Migration[5.1]
  def change
    remove_column :courses, :club
    remove_column :holes, :green_center_lat
    remove_column :holes, :green_center_lng
    remove_column :holes, :green_front_lat
    remove_column :holes, :green_front_lng
    remove_column :holes, :green_depth

    add_column :holes, :tee_pos, :float, array: true, default: []
    add_column :holes, :hole_pos, :float, array: true, default: []
  end
end
