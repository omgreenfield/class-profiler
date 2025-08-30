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
    end

    module ClassMethods
      # Profiles all instance methods including those inherited
      def profile_all_methods
        profile_methods(*instance_methods)
      end

      # Profiles non-inherited instance methods only
      def profile_instance_methods
        profile_methods(*instance_methods(false))
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
