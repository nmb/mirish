require 'sequel'
module Mirish
  # Rides 
  class Seat < Sequel::Model
    one_to_one :ride

  end
end
