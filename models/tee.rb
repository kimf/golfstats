class Tee < ActiveRecord::Base
  belongs_to :hole
  belongs_to :slope, counter_cache: :tee_count
end
