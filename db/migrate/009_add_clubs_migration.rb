class AddClubsMigration <  ActiveRecord::Migration
  def up

    create_table :clubs do |t|
      t.string  :name
      t.string  :lat
      t.string  :lng

      t.timestamps
    end

    add_index :clubs, :name

    add_column :courses, :club_id, :integer

    remove_column :courses, :lat
    remove_column :courses, :lng
  end

  def down
    drop_table :clubs
    remove_column :courses, :club_id
    add_column :courses, :lat, :string
    add_column :courses, :lng, :string
  end
end
