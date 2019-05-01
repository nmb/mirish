require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
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

    # remove expired ride every minute
    scheduler = Rufus::Scheduler.new(:lockfile => ".rufus-scheduler.lock")
    unless scheduler.down?
      scheduler.every '60s' do
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
      #p @rides.size
      p settings.connections
      erb :root
    end

    # view about page
    get "/about" do
      erb :about
    end
      
    # create new ride
    post "/rides" do
      settings.logger.info "New ride."
      params.merge!(params){ |key, value| Sanitize.clean(value) }
      r = Ride.new
      r.title = params[:title]
      r.description = params[:description]
      r.date = params[:date] + " " + params[:time]
      #r.time = Time.parse(Sanitize.clean(params[:time]))
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
      if(s && s.ride == @ride)
        s.update(free: false, name: name)
        update_json = {seatid: sid, name: name}.to_json
        settings.connections.each { |out| out << "data: #{update_json}\n\n" }
        204
      else
        404
      end
    end


    # view rides
    get "/rides/?" do
      redirect to('/')
    end
    # view ride
    get "/rides/:uuid/?" do |u|
      #not_found if u.nil?
      @ride = Ride.first(:uuid => u)
      halt 404, 'not found' unless @ride
      erb :ride
    end

    # ride event stream
    get "/rides/:uuid/eventstream/?", provides: 'text/event-stream' do |u|
        settings.logger.info("Opening stream.")
        stream :keep_open do |out|
          #out << "data: opened\n\n"
          settings.connections << out
          out.callback { settings.connections.delete(out) }
        end
    end
    # set allow_uploads
    patch "/tickets/:uuid/allow_uploads" do |u|
      @ticket = XferTickets::Ticket.first(:uuid => u)
      ownerprotected!(@ticket)
      @ticket.set_allow_uploads(params['allow_uploads'] == "true")
      @ticket.save
      200
    end

  end
end
