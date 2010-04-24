class Primary < ActiveRecord::Base
  # Constants ======================================================================================
  SEARCH_CRITERIA = [ :id, :name ]
  SORTABLE_COLUMNS = SEARCH_CRITERIA

  # Relationships ==================================================================================
  has_many :secondaries
  validates_associated :secondaries

  attr_accessor :flattened_content
end
