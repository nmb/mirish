module Mirish
  class ApplicationController < Application

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
        settings.connections[u].each { |out| out << "data: #{s.to_json}\n\n" }
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
      settings.connections[u].each { |out| out << "data: #{m.to_json}\n\n" }
      204
    end

    # view rides
    get "/rides/?" do
      redirect to('/')
    end
    # view ride
    get "/rides/:uuid/?" do |u|
      @ride = Ride.first(:uuid => u)
      if(@ride)
        erb :ride
      else
        status 404
        erb :error
      end
    end

    # ride event stream
    get "/rides/:uuid/eventstream/?", provides: 'text/event-stream' do |u|
	response.headers['X-Accel-Buffering'] = 'no'
	response.headers['Cache-Control'] = 'no-cache'
        stream :keep_open do |out|
          settings.connections[u] << out
          out.callback { settings.connections[u].delete(out) }
        end
    end

  end

end

