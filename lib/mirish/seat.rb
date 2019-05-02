require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'ostruct'
require 'sanitize'

module Mirish
  # Rides 
  class Seat
    include DataMapper::Resource

    property :id, Serial
    property :name, String, :length => 255
    property :free, Boolean, default: true

    belongs_to :ride

  end
end
