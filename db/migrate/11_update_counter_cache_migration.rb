class UpdateCounterCacheMigration <  ActiveRecord::Migration
  def up
    Slope.includes(:tees).all.each do |s|
      Slope.update_counters s.id, tee_count: s.tees.length
    end
  end
end
