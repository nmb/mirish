require 'rake'
require 'sequel'
require 'yaml'

#task :environment do
#  $LOAD_PATH.push File.expand_path("../lib", __FILE__)
#  require "mirish"
#end

ENV['RACK_ENV'] ||= 'development'

namespace :db do
  desc "Create database"
  task :create do
    db = YAML.load_file(File.dirname(__FILE__) + "/config/database.yml")[ENV['RACK_ENV']]
    ENV["PGPASSWORD"] = "#{db['password']}"
    exec "createdb",
      "-h", "#{db['host']}",
      "-U", "#{db['username']}",
      "#{db['database']}"
  end

  desc 'Run migrations'
  task :migrate, [:version] do |_t, args|
    Sequel.extension :migration
    db = Sequel.connect(YAML.load_file(File.dirname(__FILE__) + "/config/database.yml")[ENV['RACK_ENV']])
    migration_path = "db/migrations"

    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, migration_path, target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(db, migration_path)
    end
  end

  desc "Print db stats"
  task :dbstats => :environment do |t, _|
    puts "No of registered rides: #{Mirish::Ride.all.size}"
  end

  desc "Print ride uuid:s"
  task :rides => :environment do |t, _|
    Mirish::Ride.all.each do |r| 
      puts r.uuid
    end
  end

end
