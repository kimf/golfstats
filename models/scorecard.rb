class Scorecard < ActiveRecord::Base
  default_scope { order('date DESC') }

  attr_accessor :score_objects

  def self.played_between(from, to)
    where('date >= ? AND date <= ?', Date.parse(from), Date.parse(to))
  end

  def self.after_date(date)
    where('date > ?', Date.parse(date))
  end
end
