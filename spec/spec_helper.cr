require "spec"
require "../src/redis-sentinel"
require "../src/redis/config"

def use_redis5?
  ENV["REDIS_SENTINEL_TEST_V5_AUTH"]? == "true"
end

DOCKER_CLUSTER_ARGS = 
  if use_redis5?
    {host: "the-master", password: "abc", sentinels: [{:host => "172.21.0.15", :port => 26379, :password => "abcd"}, {:host => "172.21.0.20", :port => 26379, :password => "abcd"}]}
  else
    {host: "the-master", password: "abc", sentinels: [{:host => "172.22.0.15", :port => 26379}, {:host => "172.22.0.20", :port => 26380}]}
  end

def yaml_cfg_string(host = "localhost", port = 6379, unixsocket : String? = nil, password : String? = nil,
  database : Int32? = nil, url = nil, ssl = false, ssl_context : OpenSSL::SSL::Context::Client? = nil,
  dns_timeout : Int32? = nil, connect_timeout : Int32? = nil, reconnect = true, command_timeout : Int32? = nil,
  role : String? = "master", sentinels : Array(Hash(Symbol, String | Int32))? = nil)
  <<-EOF
  ---
  host: #{host}
  password: #{password}
  #{"#{{sentinels: sentinels}.to_yaml[4..-1]}" if sentinels}
  #{"dns_timeout: #{dns_timeout}" if dns_timeout}
  #{"connect_timeout: #{connect_timeout}" if connect_timeout}
  #{"command_timeout: #{command_timeout}" if command_timeout}
  EOF
end

def cfg_from_yaml(**args)
  Redis::Config.from_string yaml_cfg_string(**DOCKER_CLUSTER_ARGS.merge args)
end

def custom_cfg_from_yaml(**args)
  Redis::Config.from_string **args
end