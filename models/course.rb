class Course < ActiveRecord::Base
  belongs_to :club
  has_many :holes, dependent: :destroy
  has_many :slopes, dependent: :destroy
end
