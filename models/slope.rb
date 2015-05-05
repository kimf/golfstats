class Slope < ActiveRecord::Base
  belongs_to :course
  has_many   :tees, dependent: :destroy
end
