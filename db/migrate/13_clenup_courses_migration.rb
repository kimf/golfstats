class ClenupCoursesMigration <  ActiveRecord::Migration[5.1]
  def change
    drop_table :tees
    remove_column :slopes, :male
  end
end
