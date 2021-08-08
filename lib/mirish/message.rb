require 'sequel'
module Mirish
  # Rides 
  class Message < Sequel::Model
    one_to_one :ride
  end
end
