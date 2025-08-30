# frozen_string_literal: true

module ClassProfiler
  module Methods
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods; end

    module ClassMethods
      # Wraps a method by creating an alias to the original method creating a new
      # method in its place, executing the passed in block and returning the result
      # The given block is executed in the INSTANCE context via instance_exec.
      #
      # @yield [original_method, *args] wrapper executed in instance context
      def wrap_method(method_name, *_args, prefix: '_', &wrapper)
        wrapped_method_name = "#{prefix}#{method_name}".to_sym
        alias_method wrapped_method_name, method_name
        wrapped_method = instance_method(wrapped_method_name)

        define_method(method_name) do |*args|
          instance_exec(wrapped_method, *args, &wrapper)
        end
      end
    end
  end
end
