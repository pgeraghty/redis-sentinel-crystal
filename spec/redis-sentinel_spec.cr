require "./spec_helper"

describe Redis do
  # TODO: Write further tests

  it "works" do
    args = {host: "the-master", password: "abc", sentinels: [{:host => "172.22.0.15", :port => 26379}, {:host => "172.22.0.20", :port => 26379}]}

    r = Redis.new **args

    r.set "foo", str1 = "bar"
    str2 = r.get "foo"

    str2 == str1
  end
end
