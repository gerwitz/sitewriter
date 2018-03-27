class Site < Sequel::Model
  one_to_many :stores
  one_to_many :flows
end
