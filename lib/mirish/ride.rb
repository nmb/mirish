require 'sequel'
module Mirish
  # Rides 
  class Ride < Sequel::Model
    one_to_many :seats
    one_to_many :messages

    def before_create
      self.adminuuid = SecureRandom.uuid
    end

  end
end
