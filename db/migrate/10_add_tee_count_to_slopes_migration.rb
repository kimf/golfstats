class AddTeeCountToSlopesMigration <  ActiveRecord::Migration
  def up
    add_column :slopes, :tee_count, :integer
  end

  def down
    remove_column :slopes, :tee_count
  end
end
