# frozen_string_literal: true
require "rubygems"
require "bundler/setup"
require "rufus/scheduler"
require "sinatra/base"
require "sinatra/config_file"
require "sinatra/flash"
require "securerandom"
require "logger"
require 'pp'

require "mirish/ride.rb"
require "mirish/seat.rb"
require "mirish/message.rb"
require "mirish/application.rb"
require "mirish/controller.rb"

