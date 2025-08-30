# frozen_string_literal: true

require_relative 'class_profiler/methods'
require_relative 'class_profiler/benchmark'
require_relative 'class_profiler/logging'
require_relative 'class_profiler/memory'

module ClassProfiler
  NAME = 'class-profiler'
  VERSION = '0.1.0'

  def self.included(base)
    base.include(ClassProfiler::Benchmark)
    base.include(ClassProfiler::Memory)
    base.include(ClassProfiler::Logging)
  end
end
