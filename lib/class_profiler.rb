# frozen_string_literal: true

require_relative 'class_profiler/benchmark'
require_relative 'class_profiler/logging'
require_relative 'class_profiler/memory'

module ClassProfiler
  NAME = 'class-profiler'
  VERSION = '0.1.0'

  include Benchmark
  include Memory
  include Logging
end
