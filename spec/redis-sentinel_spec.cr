require "./spec_helper"

DOCKER_CLUSTER_ARGS = 
  if ENV["REDIS_SENTINEL_TEST_V5_AUTH"]? == "true"
    {host: "the-master", password: "abc", sentinels: [{:host => "172.21.0.15", :port => 26379, :password => "abcd"}, {:host => "172.21.0.20", :port => 26379, :password => "abcd"}]}
  else
    {host: "the-master", password: "abc", sentinels: [{:host => "172.22.0.15", :port => 26379}, {:host => "172.22.0.20", :port => 26379}]}
  end

SENTINEL_TEST_REDIS_KEY = "redis_sentinel_test_crystal_7sbSHjpL4p6gTpMw"
SENTINEL_TEST_STRING = "C4zj3rE2cpbGHwUawjndyrsYfqRrCC25"

describe Redis do
  # TODO: Write further tests
  
  it "can connect to sentinels" do
    r = Redis.new **DOCKER_CLUSTER_ARGS

    r.set SENTINEL_TEST_REDIS_KEY, SENTINEL_TEST_STRING
    value = r.get SENTINEL_TEST_REDIS_KEY

    value == SENTINEL_TEST_STRING
  end

  it "does not interfere with local Redis" do
    r = Redis.new
    
    value = r.get SENTINEL_TEST_REDIS_KEY

    value == nil
  end
end

# TODO stub Redis.new so that we can run standards tests against sentinels

require "../lib/redis/spec/redis_spec"