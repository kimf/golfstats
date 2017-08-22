class AddJsonColToScorecardsMigration <  ActiveRecord::Migration
  def up
    add_column :scorecards, :json, :json
  end

  def down
    remove_column :scorecards, :json
  end
end
