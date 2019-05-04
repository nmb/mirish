require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'ostruct'
require 'sanitize'

module Mirish
  # Rides 
  class Message
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :msg, String, :length => 255

    belongs_to :ride

  end
end
