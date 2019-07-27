require "redis"

module Redis::Sentinel
  # keep version in sync with crystal-redis
  VERSION = "2.2.1"
end

class Redis
  @master : String?

  # new overloaded constructor allowing sentinel config
  def initialize(@host = "localhost", @port = 6379, @unixsocket : String? = nil, @password : String? = nil,
                 @database : Int32? = nil, url = nil, @ssl = false, @ssl_context : OpenSSL::SSL::Context::Client? = nil,
                 @dns_timeout : Time::Span? = nil, @connect_timeout : Time::Span? = nil, @reconnect = true, @command_timeout : Time::Span? = nil,
                 # additional instance variables for role and sentinels
                 @role : String? = "master", @sentinels : Array(Hash(Symbol, String | Int32))? = nil)
    # call original Redis#initialize
    previous_def @host, @port, @unixsocket, @password, @database, url, @ssl, @ssl_context, @dns_timeout, @connect_timeout, @reconnect, @command_timeout
  end

  private def ensure_connection
    if @connection
      # Already connected, nothing to be done.
      return
    end

    if @reconnect
      connect
    else
      raise ConnectionLostError.new("Not connected to Redis server and reconnect=false")
    end
  end

  # Connects to Redis.
  private def connect
    @connection =
      if @sentinels
        # check sentinel settings, establish connection to Redis instance

        @connection = nil
        @strategy = nil

        @master = @host

        result = resolve_sentinel

        Connection.new(result[:host], result[:port], @unixsocket, @ssl_context, @dns_timeout, @connect_timeout, @command_timeout)
      else
        # revert to vanilla standalone Redis behaviour
        Connection.new(@host, @port, @unixsocket, @ssl_context, @dns_timeout, @connect_timeout, @command_timeout)
      end
    
    @strategy = Redis::Strategy::SingleStatement.new(@connection.not_nil!)
        
    if @strategy
      @strategy.not_nil!.command(["AUTH", @password]) if @password
      @strategy.not_nil!.command(["SELECT", @database.to_s]) if @database
    else
      raise ConnectionError.new("Invalid strategy")
    end

    if @sentinels
      # ported from Ruby Redis' Redis::Client::Connector::Sentinel#check
      # Check the instance is really of the role we are looking for.
      # We can't assume the command is supported since it was introduced
      # recently and this client should work with old stuff.
      begin
        role = @strategy.not_nil!.command(["role"]).as(Array)[0]
      rescue Redis::Error
        # Assume the test is passed if we can't get a reply from ROLE...
        role = @role
      end

      if role != @role
        @connection.not_nil!.close
        raise ConnectionError.new("Instance role mismatch. Expected #{@role}, got #{role}.")
      end
    end

  end

  # finds appropriate Redis instance via Sentinel
  # ported from Redis::Client::Connector::Sentinel#resolve
  def resolve_sentinel
    result = case @role
             when "master"
               resolve_master
             when "slave"
               resolve_slave
             else
               raise ArgumentError.new("Unknown instance role #{@role}")
             end

    result || raise ConnectionError.new("Unable to fetch #{@role} via Sentinel.")
  end

  # sentinel checker, attempts connection to potential sentinels and passes viable candidate to block
  # ported from Redis::Client::Connector::Sentinel#sentinel_detect
  def sentinel_detect
    @sentinels.not_nil!.each do |sentinel|
      client = Connection.new(sentinel[:host].to_s, sentinel[:port].to_i, @unixsocket, @ssl_context, @dns_timeout, @connect_timeout, @command_timeout)

      strategy = Redis::Strategy::SingleStatement.new(client.not_nil!)

      # TODO test this
      strategy.command(["AUTH", sentinel[:password].to_s]) if sentinel[:password]?

      begin
        if result = yield(strategy)
          # This sentinel responded. Make sure we ask it first next time.
          @sentinels.not_nil!.delete(sentinel)
          @sentinels.not_nil!.unshift(sentinel)

          return result
        end
      rescue ConnectionError
      ensure
        client.close
      end
    end

    raise CannotConnectError.new("No sentinels available based on #{@sentinels.inspect}")
  end

  # find a master Redis instance via a given sentinel
  # ported from Redis::Client::Connector::Sentinel#resolve_master
  def resolve_master
    sentinel_detect do |strategy|
      begin
        if reply = strategy.command(["sentinel", "get-master-addr-by-name", @master])
          {
            host: reply[0].as(String),
            port: reply[1].as(String).to_i,
          } if reply.is_a? Array(Redis::RedisValue)
        end
      rescue IndexError
        # Invalid host or port
        raise ConnectionError.new("Invalid host or port")
      end
    end
  end

  # find a slave Redis instance via a given sentinel
  # ported from Redis::Client::Connector::Sentinel#resolve_slave
  def resolve_slave
    sentinel_detect do |strategy|
      if reply = strategy.command(["sentinel", "slaves", @master])
        reply = reply.as(Array(Redis::RedisValue))
        slaves = reply.map { |s| s = s.as(Array(Redis::RedisValue)); s.each_slice(2).to_h }

        slaves.reject! { |s| s["flags"].as(String).split(",").includes?("s_down") }

        if slaves.empty?
          raise CannotConnectError.new("No slaves available.")
        else
          slave = slaves.sample

          {
            host: slave["ip"].as(String),
            port: slave["port"].as(String).to_i,
          }
        end
      end
    end
  end
end
