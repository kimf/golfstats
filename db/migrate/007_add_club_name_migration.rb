class AddClubNameMigration <  ActiveRecord::Migration
  def up
    add_column :courses, :club, :string
  end

  def down
    remove_column :courses, :club
  end
end
