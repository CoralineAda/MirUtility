class Secondary < ActiveRecord::Base
  belongs_to :primary

  def validate
    errors.add_to_base("Secondary's name cannot be illegal.") if self.name == 'illegal'
  end
end
