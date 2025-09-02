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
      #
      # @param include_zero [Boolean] include rows with zero deltas
      # @param sort_by [:objects, :bytes, :name] sort rows by allocations or name
      def memory_report(include_zero: true, sort_by: :objects)
        entries = profiled_memory.to_a
        entries.select! do |(_, data)|
          include_zero || data[:allocated_objects].to_i.nonzero? || data[:malloc_increase_bytes].to_i.nonzero?
        end

        entries.sort_by! do |(m, data)|
          case sort_by
          when :bytes then [data[:malloc_increase_bytes].to_i, m.to_s]
          when :name then [m.to_s]
          else [data[:allocated_objects].to_i, m.to_s]
          end
        end

        header = "Memory profile (#{self.class.name} instance):"
        lines = [header]
        if entries.empty?
          lines << '  (no data)'
        else
          min_objects = entries.map { |(_, d)| d[:allocated_objects].to_i }.reject { |v| v <= 0 }.min || 0
          min_bytes = entries.map { |(_, d)| d[:malloc_increase_bytes].to_i }.reject { |v| v <= 0 }.min || 0
          lines << format('%-24s %-18s %-16s %-14s %-14s', 'Method', 'Allocated Objects', 'Malloc +bytes', 'vs min objs', 'vs min bytes')
          lines << ('-' * 96)
          entries.each do |(method, data)|
            objs = data[:allocated_objects].to_i
            bytes = data[:malloc_increase_bytes].to_i
            obj_ratio = min_objects.positive? && objs.positive? ? format('%.2fx', objs.to_f / min_objects) : 'n/a'
            byte_ratio = min_bytes.positive? && bytes.positive? ? format('%.2fx', bytes.to_f / min_bytes) : 'n/a'
            lines << format('%-24s %-18d %-16d %-14s %-14s', method, objs, bytes, obj_ratio, byte_ratio)
          end
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
