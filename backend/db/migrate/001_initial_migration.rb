class InitialMigration <  ActiveRecord::Migration
  def up
    create_table :scorecards do |t|
      t.date    :date
      t.string  :course

      t.integer :par
      t.integer :strokes_out
      t.integer :strokes_in
      t.integer :strokes
      t.integer :points
      t.integer :putts
      t.integer :putts_avg
      t.integer :putts_out
      t.integer :putts_in
      t.integer :girs
      t.integer :firs
      t.integer :strokes_over_par
      t.integer :scores_count
      t.integer :not_par_three_holes
      t.integer :distance
      t.integer :consistency, array: true, null: false, default: []

      t.integer :scores, array: true, null: false, default: []

      t.timestamps
    end

    add_index :scorecards, :date
    add_index :scorecards, :course


    create_table :scores do |t|
      t.integer :scorecard_id
      t.integer :hole
      t.integer :distance
      t.integer :hcp
      t.integer :par
      t.integer :strokes
      t.integer :points
      t.integer :tee_club
      t.integer :fairway
      t.integer :putts
      t.integer :green_bunker, default: nil
      t.integer :penalties, default: nil
      t.integer :fir
      t.integer :gir
      t.integer :strokes_over_par
      t.integer :name
      t.integer :hio
      t.integer :scrambling
      t.integer :sand_save, default: nil
      t.integer :up_and_down, default: nil

      t.timestamps
    end

    add_index :scores, :scorecard_id
    add_index :scores, :hole
    add_index :scores, :fir
    add_index :scores, :gir
    add_index :scores, :scrambling
    add_index :scores, :sand_save
    add_index :scores, :up_and_down
  end

  def down
    drop_table :scorecards
    drop_table :scores
  end
end
