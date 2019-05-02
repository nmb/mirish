require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'dm-constraints'

module Mirish
  # Rides 
  class Ride
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :date, Date, required: true
    property :time, String, :length => 255, required: true
    property :title, String,:length => 255,  required: true
    property :description, Text
    property :uuid, String, unique: true, required: true, default: lambda { |r,p| SecureRandom.urlsafe_base64(n=32)}
    property :adminuuid, String, unique: true, required: true, default: lambda { |r,p| SecureRandom.urlsafe_base64(n=32)}

    has n, :seats, constraint: :destroy
    has n, :messages, constraint: :destroy

  end
end
