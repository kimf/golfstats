class AddHolesMigration <  ActiveRecord::Migration
  def up

    rename_column :courses, :holes, :holes_count

    create_table :holes do |t|
      t.integer :course_id
      t.integer :number
      t.integer :par
      t.integer :length

      t.timestamps
    end

    add_index :holes, :number
    add_index :holes, :course_id
    add_index :holes, [:course_id, :number]

    create_table :slopes do |t|
      t.integer :course_id
      t.decimal :course_rating
      t.integer :slope_value
      t.boolean :male
      t.string  :name
    end

    add_index :slopes, :course_id
  end

  def down
    drop_table :holes
    drop_table :slopes
    rename_column :courses, :holes_count, :holes
  end
end
