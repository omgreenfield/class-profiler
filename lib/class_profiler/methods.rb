# frozen_string_literal: true

module ClassProfiler
  module Methods
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods; end

    module ClassMethods
      # Helper: exclude helper methods defined by ClassProfiler modules to avoid recursion/noise
      def helper_owner_module?(owner)
        owner_name = owner.respond_to?(:name) ? owner.name : nil
        !!owner_name&.start_with?('ClassProfiler::')
      end

      # Methods that should never be wrapped on instances to avoid recursion/footguns
      RESERVED_INSTANCE_METHODS = %i[
        instance_exec instance_eval send __send__ method public_method
        respond_to? object_id __id__ class inspect to_s
      ].freeze

      # Methods that should never be wrapped on the singleton to avoid recursion/footguns
      RESERVED_SINGLETON_METHODS = %i[
        send public_send method singleton_method define_singleton_method
        instance_eval class_eval method_missing respond_to? allocate new superclass
        inspect to_s name ancestors inherited extend include prepend
        alias_method remove_method undef_method autoload autoload?
        object_id __id__
      ].freeze

      # (internal) Helper: obtain singleton class
      def singleton_class_of(klass)
        class << klass; self; end
      end

      # Select instance method names by visibility and inheritance, excluding helpers/reserved
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      # @param include_inherited [Boolean]
      # @return [Array<Symbol>]
      def select_instance_methods(visibility: :public, include_inherited: true)
        inherit = include_inherited || false
        names = case visibility
                when :public      then public_instance_methods(inherit)
                when :protected   then protected_instance_methods(inherit)
                when :private     then private_instance_methods(inherit)
                when :all         then (instance_methods(inherit) + protected_instance_methods(inherit) + private_instance_methods(inherit)).uniq
                else public_instance_methods(inherit)
                end

        names.reject { |m| RESERVED_INSTANCE_METHODS.include?(m) || m.to_s.start_with?('_') || helper_owner_module?(instance_method(m).owner) }
      end

      # Select class method names by visibility and inheritance, excluding helpers/reserved
      # @param visibility [Symbol] :public, :protected, :private, :all
      # @param include_inherited [Boolean]
      # @return [Array<Symbol>]
      def select_class_methods(visibility: :public, include_inherited: true)
        singleton = singleton_class_of(self)
        inherit = include_inherited || false

        names = case visibility
                when :public      then singleton.public_instance_methods(inherit)
                when :protected   then singleton.protected_instance_methods(inherit)
                when :private     then singleton.private_instance_methods(inherit)
                when :all         then (singleton.instance_methods(inherit) + singleton.protected_instance_methods(inherit) + singleton.private_instance_methods(inherit)).uniq
                else singleton.public_instance_methods(inherit)
                end

        names.reject { |m| RESERVED_SINGLETON_METHODS.include?(m) || m.to_s.start_with?('_') || helper_owner_module?(singleton.instance_method(m).owner) }
      end

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

      # Wrap a class method on the singleton class
      def wrap_class_method(method_name, *_args, prefix: '_', &wrapper)
        singleton = singleton_class_of(self)
        wrapped_method_name = "#{prefix}#{method_name}".to_sym
        singleton.alias_method wrapped_method_name, method_name
        singleton.define_method(method_name) do |*args, &block|
          start_time = Time.now
          result = send(wrapped_method_name, *args, &block)
          # let wrapper decide what to record/return
          # wrapper executed in singleton context
          wrapper.call(start_time, result, method_name)
        end
      end
    end
  end
end
