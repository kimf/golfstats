class AddSlopeLengthMigration <  ActiveRecord::Migration
  def up
    add_column :slopes, :length, :integer
  end

  def down
    remove_column :slopes, :length
  end
end
