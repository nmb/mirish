require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'dm-constraints'
require 'ostruct'
require 'sanitize'

module Mirish
  # Rides 
  class Ride
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :date, DateTime, required: true
    #property :time, Time, required: true
    property :title, String, required: true
    property :description, Text
    property :uuid, String, unique: true, required: true, default: lambda { |r,p| SecureRandom.urlsafe_base64(n=32)}
    property :adminuuid, String, unique: true, required: true, default: lambda { |r,p| SecureRandom.urlsafe_base64(n=32)}

    has n, :seats, constraint: :destroy


    #def initialize(params = nil)
      #self.uuid = SecureRandom.urlsafe_base64(n=32)
      #self.adminuuid = SecureRandom.urlsafe_base64(n=32)
      #if(params)
      #self.title = Sanitize.clean(params[:title])
      #self.description = Sanitize.clean(params[:description])
      #self.date = params[:date]
      #end
    #end

    def expirydate
      return self.date + Mirish::Application.settings.expiration_time
    end

  end
end
