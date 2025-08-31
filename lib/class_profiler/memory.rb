# frozen_string_literal: true

module ClassProfiler
  module Memory
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(Methods::ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      # Stores per-method memory profile results
      # { method_name => { allocated_objects: Integer, malloc_increase_bytes: Integer } }
      def profiled_memory
        @profiled_memory ||= {}
      end

      # Emits a formatted report of instance memory profiling for this object
      # Returns the formatted text. Also logs via profiler_logger if present.
      def memory_report(include_zero: true)
        header = "Memory profile (#{self.class.name} instance):"
        lines = [header]
        profiled_memory.each do |method, data|
          next if !include_zero && data[:allocated_objects].to_i.zero? && data[:malloc_increase_bytes].to_i.zero?
          lines << "  #{method}: allocated_objects=#{data[:allocated_objects]}, malloc_increase_bytes=#{data[:malloc_increase_bytes]}"
        end
        text = lines.join("\n")
        begin
          profiler_logger&.info(text)
        rescue => e
          warn("[class-profiler] memory_report logging failed: #{e.class}: #{e.message}")
        end
        text
      end
    end

    module ClassMethods
      # Profiles all instance methods including those inherited
      # @param visibility [Symbol] :public, :protected, :private, :all
      def profile_all_methods(visibility: :public)
        names = select_instance_methods(visibility: visibility, include_inherited: true)
        profile_methods(*names)
      end

      # Profiles non-inherited instance methods only
      # @param visibility [Symbol] :public, :protected, :private, :all
      def profile_instance_methods(visibility: :public)
        names = select_instance_methods(visibility: visibility, include_inherited: false)
        profile_methods(*names)
      end

      # Wraps each method and records allocation deltas per call
      #
      # @param method_names [Array<Symbol>]
      def profile_methods(*method_names)
        require 'objspace'

        method_names.each do |method_name|
          wrap_method method_name do |original, *args, &block|
            before_alloc_objects = GC.stat[:total_allocated_objects]
            before_malloc_bytes = GC.stat[:malloc_increase_bytes] || 0

            result = original.bind(self).call(*args, &block)

            after_alloc_objects = GC.stat[:total_allocated_objects]
            after_malloc_bytes = GC.stat[:malloc_increase_bytes] || 0

            profiled_memory[method_name] = {
              allocated_objects: after_alloc_objects - before_alloc_objects,
              malloc_increase_bytes: after_malloc_bytes - before_malloc_bytes
            }

            result
          end
        end
      end

    end
  end
end
