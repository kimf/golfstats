class AddFieldsToScorecards <  ActiveRecord::Migration
  def change
    add_column :scorecards, :scoring_distribution, :integer, array: true, null: false, default: []
    add_column :scorecards, :putts_gir_avg, :float
  end
end
