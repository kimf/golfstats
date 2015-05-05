class AddCoursesMigration <  ActiveRecord::Migration
  def up

  create_table :courses do |t|
      t.string  :name
      t.integer :holes
      t.integer :par
      t.string  :lat
      t.string  :lng

      t.timestamps
    end

    add_index :courses, :name
  end

  def down
    drop_table :courses
  end
end
