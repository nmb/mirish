require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'dm-serializer'
require 'ostruct'
require "sinatra/config_file"
require 'time'
require 'json'


module Mirish
  class Application < Sinatra::Base

    register Sinatra::ConfigFile

    DataMapper::Model.raise_on_save_failure = true
    # This is to enable streaming tar:
    class Sinatra::Helpers::Stream
      alias_method :write, :<<
    end

    set server: 'thin'
    configure :production, :development do
      set :logging, nil
      logger = Logger.new STDOUT
      logger.level = Logger::INFO
      logger.datetime_format = '%a %d-%m-%Y %H%M '
      set :logger, logger
      set :show_exceptions, true
      set :dump_errors, true
      set :views, "#{File.dirname(__FILE__)}/views"
      #connections = []
      #set :connections, connections
      set connections: []

      SiteConfig = OpenStruct.new(
        :title => 'Mirish',
        :author => 'Mikael Borg',
        :repo => 'https://github.com/nmb/mirish',
      )

      DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/../../tmp/#{Sinatra::Base.environment}.db"))
      DataMapper.finalize
      DataMapper.auto_upgrade!

    end

    # refuse to run as root
    if Process.uid == 0
      STDERR.puts 'Please do not run this as root.' 
      exit 1
    end

    register Sinatra::Flash

    # remove expired rides every 12h
    scheduler = Rufus::Scheduler.new(:lockfile => ".rufus-scheduler.lock")
    unless scheduler.down?
      scheduler.every '12h' do
        Ride.all.each do |t|
          if(DateTime.now > t.date)
            settings.logger.info "Deleting expired ride #{t.uuid}"
            t.destroy
          end
        end
      end
    end

    # root page
    get "/" do
      @rides = Ride.all
      erb :root
    end

    # view about page
    get "/about" do
      erb :about
    end
      
    # create new ride
    post "/rides" do
      params.merge!(params){ |key, value| Sanitize.clean(value) }
      r = Ride.new
      r.title = params[:title]
      r.description = params[:description]
      r.date = params[:date]
      r.time = params[:time]
      r.save
      params[:seats].to_i.times{ r.seats.create }
      redirect to('/rides/' + r.uuid)
    end

    # delete ride
    delete "/rides/:uuid/?" do |u|
      @ride = Mirish::Ride.first(:adminuuid => u)
      halt 404, 'not found' unless @ride
      @ride.destroy 
      halt 200
    end

    # claim seat
    post "/rides/:uuid/:seatid/?" do |u,sid|
      settings.logger.info("Claiming seat #{sid}.")
      @ride = Mirish::Ride.first(:uuid => u)
      halt 404, 'not found' unless @ride
      s = Seat.get(sid)
      name = Sanitize.clean(params[:name])
      if(s && s.ride == @ride && s.free)
        s.update(free: false, name: name)
        settings.connections.each { |out| out << "data: #{s.to_json}\n\n" }
        204
      else
        halt(404)
      end
    end

    # add message
    post "/rides/:uuid/?" do |u|
      @ride = Mirish::Ride.first(:uuid => u)
      halt 404, 'not found' unless @ride
      msg = Sanitize.clean(params[:message])
      m = @ride.messages.create(msg: msg)
      settings.connections.each { |out| out << "data: #{m.to_json}\n\n" }
      204
    end

    # view rides
    get "/rides/?" do
      redirect to('/')
    end
    # view ride
    get "/rides/:uuid/?" do |u|
      @ride = Ride.first(:uuid => u)
      halt 404, 'not found' unless @ride
      erb :ride
    end

    # ride event stream
    get "/rides/:uuid/eventstream/?", provides: 'text/event-stream' do |u|
        stream :keep_open do |out|
          settings.connections << out
          out.callback { settings.connections.delete(out) }
        end
    end

  end
end
