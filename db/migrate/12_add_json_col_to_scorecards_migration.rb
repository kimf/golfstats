class AddJsonColToScorecardsMigration <  ActiveRecord::Migration[5.1.4]
  def up
    add_column :scorecards, :json, :json
  end

  def down
    remove_column :scorecards, :json
  end
end
