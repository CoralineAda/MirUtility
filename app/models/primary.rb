class Primary < ActiveRecord::Base
  has_many :secondaries
  validates_associated :secondaries
end
