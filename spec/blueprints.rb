require 'faker'
require 'machinist/active_record'
require 'sham'

Sham.first_name { Faker::Name.first_name }
Sham.last_name { Faker::Name.last_name }
Sham.password { Faker::Lorem.sentence.split.to_s[0..12] << rand(10).to_s }

User.blueprint do
  first_name
  last_name
  email { Faker::Internet.email }
  activated_at { 5.days.ago.to_s :db }
end

