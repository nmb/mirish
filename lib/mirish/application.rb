require "sinatra/config_file"
require 'time'
require 'json'


module Mirish
  class Application < Sinatra::Base

    register Sinatra::ConfigFile
    basedir= Rack::Directory.new('').root
    config_file(ENV["CONFIGURATION_FILE"] || "#{basedir}/config/config.yml")

    # This is to enable streaming tar:
    class Sinatra::Helpers::Stream
      alias_method :write, :<<
    end

    set server: 'thin'
    configure  do
      set :logging, nil
      logger = Logger.new STDOUT
      logger.level = Logger::INFO
      logger.datetime_format = '%a %d-%m-%Y %H%M '
      set :logger, logger
      set :dump_errors, true
      set :views, "#{File.dirname(__FILE__)}/views"
      set connections: Hash.new {|h,k| h[k] = Array.new }

      SiteConfig = {
        :title => settings.apptitle,
        :author => 'Mikael Borg',
        :repo => 'https://github.com/nmb/mirish',
      }
      Sequel::Model.plugin :timestamps
      Sequel::Model.plugin :json_serializer
      Sequel::Model.plugin :uuid, { field: :id }
      Sequel::Model.plugin :auto_validations,
        not_null: :presence, unique_opts: { only_if_modified: true }



    end

    configure :testing, :development do
      set :show_exceptions, true
    end

    configure :production do
      if(ENV["DATABASE_URL"] )
        dbstring = ENV["DATABASE_URL"]
      else
        dbstring = "postgres://#{settings.dbuser}:#{settings.dbpassword}@#{settings.dbhost}/#{settings.database}"
      end
    end
    DB = Sequel.connect YAML.load_file(basedir + File.expand_path('/config/database.yml', __dir__))[ENV['RACK_ENV']],
                   loggers: [Logger.new($stdout)]


    # refuse to run as root
    if Process.uid == 0
      STDERR.puts 'Please do not run this as root.' 
      exit 1
    end

    register Sinatra::Flash

    scheduler = Rufus::Scheduler.new(:frequency => 10)
    unless scheduler.down?
      # remove expired rides every 12h
      scheduler.every '24h' do
        Ride.all.each do |t|
          if(DateTime.now.to_date > t.date.to_date)
            settings.logger.info "Deleting expired ride #{t.id}"
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
