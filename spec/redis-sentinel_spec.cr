require "./spec_helper"

rnd = Random.new
redis_key = "redis_sentinel_test_crystal_#{rnd.hex}"
test_string = "C4zj3rE2cpbGHwUawjndyrsYfqRrCC25_#{rnd.hex}"

describe Redis do
  # TODO: Write further tests
  
  it "can connect to sentinels" do
    redis = Redis.new **DOCKER_CLUSTER_ARGS

    redis.set redis_key, test_string
    value = redis.get redis_key

    value.should eq test_string
  end

  it "does not interfere with local Redis" do
    redis = Redis.new
    
    value = redis.get redis_key

    value.should be_nil
  end
end

# TODO stub Redis.new so that we can run standards tests against sentinels

require "../lib/redis/spec/redis_spec"