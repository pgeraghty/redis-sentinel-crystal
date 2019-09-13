require "yaml"


class Redis::Config
  # use Serializable module instead of mapping, see https://github.com/crystal-lang/crystal/issues/6441#issuecomment-407555887
  # this allows us to include JSON::Serializable too; no additional work
  include YAML::Serializable

  property host = "localhost"
  property port = 6379
  property url : String?
  property unixsocket : String?
  property password : String?
  property database : Int32?
  
  property ssl = false
  @[YAML::Field(ignore: true)]
  property ssl_context : OpenSSL::SSL::Context::Client?

  @[YAML::Field(converter: TimeSpanSeconds)]
  property dns_timeout : Time::Span?
  @[YAML::Field(converter: TimeSpanSeconds)]
  property connect_timeout : Time::Span?
  @[YAML::Field(converter: TimeSpanSeconds)]
  property command_timeout : Time::Span?
  property reconnect = true

  # additional instance variables for role and sentinels
  property role = "master"
  property sentinels : Array(Sentinel)?

  struct Sentinel
    include YAML::Serializable

    property host : String?
    property port = 26379
    property password : String?

    def to_h
      h = {} of Symbol => String | Int32
      
      h[:host] = @host.not_nil! if @host.is_a? String
      h[:port] = @port.not_nil! if @port.is_a? Int32
      h[:password] = @password.not_nil! if @password.is_a? String

      h
    end
  end


  def initialize(@host = "localhost", @port = 6379, @unixsocket : String? = nil, @password : String? = nil,
      @database : Int32? = nil, url = nil, @ssl = false, @ssl_context : OpenSSL::SSL::Context::Client? = nil,
      @dns_timeout : Time::Span? = nil, @connect_timeout : Time::Span? = nil, @reconnect = true, @command_timeout : Time::Span? = nil,
      # additional instance variables for role and sentinels
      @role : String? = "master", sentinels : Array(Hash(Symbol, String | Int32))? = nil)

      @sentinels = Array(Sentinel).from_yaml sentinels.to_yaml
  end

  # hacky replacement for args to Redis#initialize
  def to_args
    sentinels = [] of Hash(Symbol, String | Int32)
    # YAML.parse(@sentinels.to_yaml).as_a.each { |x| sentinels << x }
    @sentinels.not_nil!.each { |s| sentinels << s.to_h }

    { 
      host: @host, port: @port, unixsocket: @unixsocket, password: @password,
      database: @database, url: @url, ssl: @ssl, ssl_context: @ssl_context,
      dns_timeout: @dns_timeout, connect_timeout: @connect_timeout, reconnect: @reconnect, command_timeout: @command_timeout,
      role: @role, sentinels: sentinels
    }    
  end

  def redis
    Redis.new **to_args
  end

  def self.from_file(file_path : String)
    str = File.read(file_path)
    Config.from_yaml str
  end

  def self.from_string(str : String)
    Config.from_yaml str
  end

  def cast()
    # TODO to NamedTuple?
  end

  struct ::TimeSpanSeconds
    def self.from_yaml(context, node)
      # perhaps use Time::Span.new(*, seconds : Int, nanoseconds : Int)?
      Time::Span.new(0, 0, node.as(YAML::Nodes::Scalar).value.to_i)
    end
  
    def self.to_yaml(time_span, yaml)    
      yaml.scalar time_span.seconds
    end
  end
end