class AddUserIdMigration <  ActiveRecord::Migration
  def change
    add_column :scorecards, :user_id, :integer
    add_column :scores, :user_id, :integer

    add_index :scorecards, :user_id
    add_index :scores, :user_id
  end
end
