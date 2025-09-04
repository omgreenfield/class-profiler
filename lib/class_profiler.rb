# frozen_string_literal: true

require_relative 'class_profiler/methods'
require_relative 'class_profiler/performance'
require_relative 'class_profiler/logging'
require_relative 'class_profiler/memory'

module ClassProfiler
  NAME = 'class-profiler'
  VERSION = '0.1.0'

  def self.included(base)
    base.include(ClassProfiler::Performance)
    base.include(ClassProfiler::Memory)
    base.include(ClassProfiler::Logging)
    base.include(InstanceMethods)
  end

  module InstanceMethods
    def profile
      perf = performance.transform_values do |value|
        if value.is_a?(Hash)
          { time: value[:time] }
        else
          { time: value }
        end
      end
      mem = memory.transform_values { |values| { objects: values[:allocated_objects], bytes: values[:malloc_increase_bytes] } }
      perf.merge(mem) { |_k, a, b| a.merge(b) }
    end

    def profile_report(include_zero: true, sort_index: 0)
      headers = %w[Method Time Objects Bytes]
      entries = profile.map { |method, values| [method, values[:time], values[:objects], values[:bytes]] }
      print_report(entries, headers: headers, include_zero:, sort_index:)
    end
  end
end
