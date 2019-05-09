$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "mirish"

map '/' do
  run Mirish::ApplicationController
end
