# frozen_string_literal: true

require_relative 'class_profiler/benchmark'
require_relative 'class_profiler/logging'
require_relative 'class_profiler/memory'

module ClassProfiler
  NAME = 'class-profiler'
  VERSION = '0.1.0'

  # Including ClassProfiler in your class will include all submodules:
  # Benchmark, Memory, and Logging. This ensures the class-level APIs like
  # `benchmark_methods` and `profile_methods` are available on your class.
  def self.included(base)
    base.include(ClassProfiler::Benchmark)
    base.include(ClassProfiler::Memory)
    base.include(ClassProfiler::Logging)
  end
end
