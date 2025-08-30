# frozen_string_literal: true

##
# Benchmarks all or specific instance methods within a class.
#
# @example
=begin
  class MyClass
    include Benchmark

    def method1
    end

    def method2
    end

    # Benchmark specific methods
    benchmark_methods :method1, :method2

    # Benchmark all non-inherited instance methods
    benchmark_instance_methods

    # Benchmark all instance methods including those inherited
    # NOTE: this must be called after all methods are defined (i.e. end of the class)
    benchmark_all_methods
  end

  my_object = MyClass.new
  my_object.method1
  my_object.method2
  my_object.benchmarked # => { method1: <result in seconds>, method2: <result in seconds> }
=end
module ClassProfiler
  module Benchmark
    def self.included(base)
      base.extend(ClassMethods)
      # Ensure the including class has access to wrap_method
      base.extend(Methods::ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      ##
      # @return [Hash<Symbol, Float>] the benchmarked methods and their execution times
      def benchmarked
        @benchmarked ||= {}
      end
    end

    module ClassMethods
      # Class-level timings for class methods
      def class_benchmarked
        @class_benchmarked ||= {}
      end

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
      ].freeze

      # (internal) Helper: obtain singleton class
      def singleton_class_of(klass)
        class << klass; self; end
      end

      ##
      # Benchmarks instance methods and inherited instance methods
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_all_methods(visibility: :public)
        names = case visibility
                when :public      then public_instance_methods(true)
                when :protected   then protected_instance_methods(true)
                when :private     then private_instance_methods(true)
                when :all         then (instance_methods(true) + protected_instance_methods(true) + private_instance_methods(true)).uniq
                else public_instance_methods(true)
                end

        # Exclude helper methods defined by ClassProfiler modules (e.g., #benchmarked)
        names = names.reject do |m|
          RESERVED_INSTANCE_METHODS.include?(m) || m.to_s.start_with?('_') || helper_owner_module?(instance_method(m).owner)
        end
        benchmark_methods(*names)
      end

      ##
      # Benchmarks non-inherited instance methods
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_instance_methods(visibility: :public)
        names = case visibility
                when :public      then public_instance_methods(false)
                when :protected   then protected_instance_methods(false)
                when :private     then private_instance_methods(false)
                when :all         then (instance_methods(false) + protected_instance_methods(false) + private_instance_methods(false)).uniq
                else public_instance_methods(false)
                end

        names = names.reject do |m|
          RESERVED_INSTANCE_METHODS.include?(m) || m.to_s.start_with?('_') || helper_owner_module?(instance_method(m).owner)
        end
        benchmark_methods(*names)
      end

      ##
      # Records how long each method call takes and saves it to `benchmarked` hash
      #
      # @param method_names [Array<Symbol>] the names of the methods to benchmark
      def benchmark_methods(*method_names)
        method_names.each do |method_name|
          wrap_method method_name do |original, *args, &block|
            start_time = Time.now
            result = original.bind(self).call(*args, &block)
            end_time = Time.now
            benchmarked[method_name] = end_time - start_time
            result
          end
        end
      end

      ##
      # Benchmarks explicit class methods by name
      def benchmark_class_methods(*method_names)
        singleton = singleton_class_of(self)
        method_names.each do |method_name|
          wrapped_method_name = "_#{method_name}".to_sym
          singleton.alias_method wrapped_method_name, method_name
          singleton.define_method(method_name) do |*args, &block|
            start_time = Time.now
            result = send(wrapped_method_name, *args, &block)
            end_time = Time.now
            class_benchmarked[method_name] = end_time - start_time
            result
          end
        end
      end

      ##
      # Benchmarks class methods defined only on this class (non-inherited)
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_own_class_methods(visibility: :public)
        singleton = singleton_class_of(self)
        names = case visibility
                when :public      then singleton.public_instance_methods(false)
                when :protected   then singleton.protected_instance_methods(false)
                when :private     then singleton.private_instance_methods(false)
                when :all         then (singleton.instance_methods(false) + singleton.protected_instance_methods(false) + singleton.private_instance_methods(false)).uniq
                else singleton.public_instance_methods(false)
                end

        names = names.reject do |m|
          RESERVED_SINGLETON_METHODS.include?(m) || m.to_s.start_with?('_') || helper_owner_module?(singleton.instance_method(m).owner)
        end
        benchmark_class_methods(*names)
      end

      ##
      # Benchmarks class methods including inherited ones
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_all_class_methods(visibility: :public)
        singleton = singleton_class_of(self)
        names = case visibility
                when :public      then singleton.public_instance_methods(true)
                when :protected   then singleton.protected_instance_methods(true)
                when :private     then singleton.private_instance_methods(true)
                when :all         then (singleton.instance_methods(true) + singleton.protected_instance_methods(true) + singleton.private_instance_methods(true)).uniq
                else singleton.public_instance_methods(true)
                end

        names = names.reject do |m|
          RESERVED_SINGLETON_METHODS.include?(m) || m.to_s.start_with?('_') || helper_owner_module?(singleton.instance_method(m).owner)
        end
        benchmark_class_methods(*names)
      end
    end
  end
end
