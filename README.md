# Redis Sentinel for Crystal

[![Build Status](https://travis-ci.com/pgeraghty/redis-sentinel-crystal.svg?branch=master)](https://travis-ci.com/pgeraghty/redis-sentinel-crystal)

Basic Redis Sentinel support for Crystal. Ported directly from the [Ruby Redis gem](https://github.com/redis/redis-rb).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     redis-sentinel:
       github: pgeraghty/redis-sentinel-crystal
   ```

2. Run `shards install`

## Usage

```crystal
require "redis-sentinel"
```

Given the environment established via the [example Redis 4 Docker Compose file](docker/redis4/docker-compose.yml), the following should execute successfully:

```crystal
r = Redis.new host: "the-master", password: "abc", sentinels: [{:host => "172.22.0.15", :port => 26379}, {:host => "172.22.0.20", :port => 26379}]
```

Due to the implementation monkey-patching the base Redis shard, you can also use Redis::PooledClient with the arguments above.

Redis version 5.0.1 and above support password protection for Sentinel instances (in addition to the underlying Redis infrastructure) if they are configured with the "requirepass" directive (as per this [commit](https://github.com/antirez/redis/commit/fa675256c127963c74ea68f8bab22ef105bada02)). To configure this in the client, you simply add a password to the hash, so to connect to the Sentinel instances established in the [example Redis 5 Docker Compose file](docker/redis5/docker-compose.yml), you'd use:

```crystal
r = Redis.new host: "the-master", password: "abc", sentinels: [{:host => "172.21.0.15", :port => 26379, :password => "abcd"}, {:host => "172.21.0.20", :port => 26379, :password => "abcd"}]
```

<!-- TODO: Write further usage instructions here -->

## Development

Testing and development require a functional Redis Sentinel configuration; I have provided [Docker Compose](https://docs.docker.com/compose/) files to establish these for Redis [4](docker/redis4/docker-compose.yml) or [5](docker/redis5/docker-compose.yml). Both set up a separate static network so that IP addresses are pre-established.

TODO experiment with SSL configuration, similar to the following from Ruby:
```ruby
:ssl_params => {
  :ca_file => "/path/to/ca.crt",
  :cert    => OpenSSL::X509::Certificate.new(File.read("client.crt")),
  :key     => OpenSSL::PKey::RSA.new(File.read("client.key"))
}
```

<!-- TODO: Write further development instructions here -->

## Contributing

1. Fork it (<https://github.com/pgeraghty/redis-sentinel-crystal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Paul Geraghty](https://github.com/pgeraghty) - creator and maintainer
