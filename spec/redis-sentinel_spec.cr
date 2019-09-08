require "./spec_helper"

DOCKER_CLUSTER_ARGS = 
  if ENV["REDIS_SENTINEL_TEST_V5_AUTH"]? == "true"
    {host: "the-master", password: "abc", sentinels: [{:host => "172.21.0.15", :port => 26379, :password => "abcd"}, {:host => "172.21.0.20", :port => 26379, :password => "abcd"}]}
  else
    {host: "the-master", password: "abc", sentinels: [{:host => "172.22.0.15", :port => 26379, :password => "abcd"}, {:host => "172.22.0.20", :port => 26379}]}
  end

describe Redis do
  # TODO: Write further tests
  
  it "can connect to sentinels" do
    r = Redis.new **DOCKER_CLUSTER_ARGS

    r.set "foo", str1 = "bar"
    str2 = r.get "foo"

    str2 == str1
  end

end

# TODO stub Redis.new so that we can run standards tests against sentinels

require "../lib/redis/spec/redis_spec"