# frozen_string_literal: true

module ClassProfiler
  module Memory
    def self.included(base)
      base.extend(ClassMethods)
      base.extend(Methods::ClassMethods)
      base.include(InstanceMethods)
      base.include(ClassProfiler::Logging)
    end

    module InstanceMethods
      # Stores per-method memory results
      # { method_name => { allocated_objects: Integer, malloc_increase_bytes: Integer } }
      def memory
        @memory ||= {}
      end

      # Prints report of each method's allocated objects and bytes used
      #
      # @param include_zero [Boolean] include rows with zero deltas (default: true)
      # @param sort_index [Integer] 0 for method, 1 for objects, 2 for bytes
      # @return [Hash] memory entries
      def memory_report(include_zero: true, sort_index: 0)
        headers = %w[Method Objects Bytes]
        entries = memory.map { |method, values| [method] + values.values }
        print_report(entries, headers: headers, include_zero:, sort_index:)
      end
    end

    module ClassMethods
      # Unified API to select and track instance methods' memory
      #
      # @param inherited [Boolean] include inherited instance methods
      # @param public [Boolean] include public methods
      # @param protected [Boolean] include protected methods
      # @param private [Boolean] include private methods
      def track_memory(inherited: false, public: true, protected: true, private: true)
        include_public = binding.local_variable_get(:public)
        include_protected = binding.local_variable_get(:protected)
        include_private = binding.local_variable_get(:private)

        names = []
        names |= select_instance_methods(visibility: :public, include_inherited: inherited) if include_public
        names |= select_instance_methods(visibility: :protected, include_inherited: inherited) if include_protected
        names |= select_instance_methods(visibility: :private, include_inherited: inherited) if include_private
        measure_memory_for_methods(*names)
      end
      # (unified) Use track_memory to configure which methods are wrapped

      # Wraps each method and records allocation deltas per call
      #
      # @param method_names [Array<Symbol>]
      private def measure_memory_for_methods(*method_names)
        require 'objspace'

        method_names.each do |method_name|
          wrap_method method_name do |original, *args, &block|
            before_alloc_objects = GC.stat[:total_allocated_objects]
            before_malloc_bytes = GC.stat[:malloc_increase_bytes] || 0

            result = original.bind(self).call(*args, &block)

            after_alloc_objects = GC.stat[:total_allocated_objects]
            after_malloc_bytes = GC.stat[:malloc_increase_bytes] || 0

            memory[method_name] = {
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
