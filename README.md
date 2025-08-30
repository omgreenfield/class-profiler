ClassProfiler: benchmark method speed and profile memory allocations in Ruby classes

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'class-profiler'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install class-profiler
```

### Usage

Include `ClassProfiler` in your class. Use the class-level helpers to wrap methods.

```ruby
class Report
  include ClassProfiler

  def fetch
    sleep 0.01
    'ok'
  end

  def allocate
    Array.new(1000) { 'x' * 10 }
  end

  benchmark_methods :fetch
  profile_methods :allocate
end

r = Report.new
r.fetch
r.allocate

r.benchmarked        # => { fetch: 0.0102 }
r.profiled_memory    # => { allocate: { allocated_objects: 1005, malloc_increase_bytes: 8192 } }
```

Helpers are also available to target all methods:

- `benchmark_all_methods` / `benchmark_instance_methods`
- `profile_all_methods` / `profile_instance_methods`

### API

- `benchmarked` (instance): Hash of method name to elapsed seconds (Float)
- `profiled_memory` (instance): Hash of method name to allocation deltas
  - `allocated_objects` (Integer)
  - `malloc_increase_bytes` (Integer)

### Composing with wrap_method

You can compose custom behaviors using the built-in `wrap_method` helper from `ClassProfiler::Methods`.
This is the same mechanism used by the Benchmark and Memory modules under the hood.

```ruby
class Widget
  include ClassProfiler

  def compute(x, y)
    x + y
  end

  # Add custom logging around the original implementation
  wrap_method :compute do |original, *args|
    profiler_logger.info("compute called with #{args.inspect}")
    result = original.bind(self).call(*args)
    profiler_logger.info("compute returned #{result}")
    result
  end

  # You can still benchmark or profile the same method
  benchmark_methods :compute
  # profile_methods :compute
end

w = Widget.new
w.compute(2, 3)
w.benchmarked[:compute] # => elapsed seconds
```

### Requirements

- Ruby >= 3.1

### Development

- Run `bin/setup` to install dependencies
- Run `rake` to execute tests and RuboCop
- Run `bin/console` to experiment in Pry

### Contributing

Bug reports and pull requests are welcome on GitHub at `https://github.com/omgreenfield/class-profiler`.

### License

The gem is available as open source under the terms of the MIT License.
