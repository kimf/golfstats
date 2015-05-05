class Course < ActiveRecord::Base
  has_many :holes, dependent: :destroy
  has_many :slopes, dependent: :destroy
end
