require 'faker'
require 'machinist/active_record'

Primary.blueprint do
  name { Faker::Lorem.words }
end
