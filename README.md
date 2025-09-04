ClassProfiler: track performance and memory allocations in Ruby classes

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

Include `ClassProfiler` in your class. Use the unified class-level helpers to wrap methods.

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

  # Track non-inherited public/protected/private instance methods (default)
  track_performance
  track_memory
end

r = Report.new
r.fetch
r.allocate

# Per-method metrics
r.performance        # => { fetch: { time: 0.0102, total: 0.0306 } }
r.memory             # => { allocate: { allocated_objects: 1005, malloc_increase_bytes: 8192 } }

# Combined view (performance + memory)
r.profile            # => { fetch: { time: 0.0102 }, allocate: { objects: 1005, bytes: 8192 } }

# Reports
r.performance_report # prints a table of last time and total time
r.memory_report      # prints a table of allocations/bytes
r.profile_report     # prints a combined table
```

Selection is controlled via flags on the unified helpers:

```ruby
# Include inherited methods?
track_performance inherited: true
track_memory inherited: true

# Choose visibilities (public/protected/private default to true)
track_performance protected: false, private: false
track_memory public: true, protected: false, private: false
```

### API

- `track_performance(inherited: false, public: true, protected: true, private: true)`
- `track_memory(inherited: false, public: true, protected: true, private: true)`
- `performance` (instance): Hash of method name → `{ time: Float, total: Float }`
- `memory` (instance): Hash of method name → allocation deltas
  - `allocated_objects` (Integer)
  - `malloc_increase_bytes` (Integer)
- `profile` (instance): Combined Hash of method name → `{ time:, objects:, bytes: }`
- `performance_report`, `memory_report`, `profile_report` (instance): print tabular reports

### Composing with wrap_method

You can compose custom behaviors using the built-in `wrap_method` helper from `ClassProfiler::Methods`.
This is the same mechanism used by the Performance and Memory modules under the hood.

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
  track_performance
  # track_memory
end

w = Widget.new
w.compute(2, 3)
w.performance[:compute] # => { time:, total: }
```

### Requirements

- Ruby >= 3.1

### Development

- Run `bin/setup` to install dependencies
- Run `rake` to execute tests and RuboCop
- Run `bin/console` to experiment in Pry

### Examples (speed vs memory trade-offs)

Explore the gem with runnable examples that contrast time vs memory usage for common problems.

Run all examples:

```bash
bundle exec rake examples
```

What you'll see:

```text
=== Two Sum: brute_force (low memory, slower) vs hashmap (higher memory, faster) ===
Input SIZE=5000

Summary (lower time is better; lower allocations usually better):
Method           Time (s)     Allocated Objects     Malloc +bytes
----------------------------------------------------------------------
brute_force      0.456789     12345                 0
hashmap          0.012345     45678                 8192

Speed: hashmap is 37.00x faster than brute_force
Memory: hashmap allocates 3.70x more objects than brute_force

Raw reports:
...
```

You can run individual examples and tune sizes:

```bash
# Two Sum: brute force vs hash map
SIZE=10000 bundle exec ruby examples/two_sum.rb

# Primes: trial division vs sieve of Eratosthenes
N=50000 bundle exec ruby examples/primes.rb
```

Each example prints a concise table plus a human-readable conclusion highlighting the trade-off (e.g. "sieve is 10x faster but allocates 4x more objects").

### Contributing

Bug reports and pull requests are welcome on GitHub at `https://github.com/omgreenfield/class-profiler`.

### License

The gem is available as open source under the terms of the MIT License.
