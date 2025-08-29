module ClassProfiler
  module Methods
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
    end

    ##
    # TODO: ensure that this actually works
    module ClassMethods
      def wrap_method(method_name, *args, prefix: '_', &block)
        wrapped_method_name = "#{prefix}#{method_name}".to_sym
        alias_method wrapped_method_name, method_name
        wrapped_method = instance_method(wrapped_method_name)

        define_method(method_name) do |*args, &block|
          yield wrapped_method, *args
        end
      end
    end
  end
end
