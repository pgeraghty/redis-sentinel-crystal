require "../spec_helper"


cfg_from_kwarg = Redis::Config.new **DOCKER_CLUSTER_ARGS

rnd = Random.new
redis_key = "redis_sentinel_test_crystal_#{rnd.hex}"
test_string = "C4zj3rE2cpbGHwUawjndyrsYfqRrCC25_#{rnd.hex}"


describe Redis::Config do
  it "can configure Redis from a YAML string" do
    cfg_from_yaml.to_yaml.should eq cfg_from_kwarg.to_yaml
    
    redis = cfg_from_yaml.redis
    redis.should be_a Redis

    redis.set redis_key, test_string
    value = redis.get redis_key

    value.should eq test_string
  end

  it "can configure Redis from a YAML file" do
    tempfile = File.tempfile "yaml_cfg"
    File.write(tempfile.path, yaml_cfg_string **DOCKER_CLUSTER_ARGS)
    
    cfg_from_yaml_file = Redis::Config.from_file tempfile.path
    tempfile.delete
    
    cfg_from_yaml_file.to_yaml.should eq cfg_from_yaml.to_yaml    

    redis = cfg_from_yaml_file.redis
    redis.should be_a Redis

    redis.set redis_key, test_string
    value = redis.get redis_key

    value.should eq test_string
  end

  describe "passes parameters to Redis" do
    it "configures DNS timeout successfully" do
      i = rnd.rand 1000      
      cfg = cfg_from_yaml dns_timeout: i      
      t = Time::Span.new(0, 0, i)
      
      cfg.dns_timeout.should eq t
      cfg.redis.@dns_timeout.should eq t
    end

    it "configures connection timeout successfully" do
      i = rnd.rand 1000      
      cfg = cfg_from_yaml connect_timeout: i      
      t = Time::Span.new(0, 0, i)
      
      cfg.connect_timeout.should eq t
      cfg.redis.@connect_timeout.should eq t
    end

    it "configures command timeout successfully" do
      i = rnd.rand 1000      
      cfg = cfg_from_yaml command_timeout: i      
      t = Time::Span.new(0, 0, i)
      
      cfg.command_timeout.should eq t
      cfg.redis.@command_timeout.should eq t
    end
  end
end