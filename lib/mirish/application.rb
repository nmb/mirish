require 'dm-core'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'
require 'dm-migrations'
require 'dm-serializer'
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
      set connections: Hash.new {|h,k| h[k] = Array.new }

      SiteConfig = {
        :title => 'Mirish',
        :author => 'Mikael Borg',
        :repo => 'https://github.com/nmb/mirish',
      }

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

    scheduler = Rufus::Scheduler.new(:frequency => 10)
    unless scheduler.down?
      # remove expired rides every 12h
      scheduler.every '12h' do
        Ride.all.each do |t|
          if(DateTime.now > t.date)
            settings.logger.info "Deleting expired ride #{t.uuid}"
            t.destroy
          end
        end
      end
      # delete empty connections
      scheduler.every '1m' do
        settings.connections.delete_if{|k,v| v.empty?}
      end
    end

  end
end
