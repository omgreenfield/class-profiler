# frozen_string_literal: true

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
      # @return [Hash<Symbol, Float>] the benchmarked methods and their execution times
      def benchmarked
        @benchmarked ||= {}
      end
    end

    module ClassMethods
      # @return [Hash<Symbol, Float>] the benchmarked class methods and their execution times
      def class_benchmarked
        @class_benchmarked ||= {}
      end

      include Methods::ClassMethods

      # Benchmarks instance methods and inherited instance methods
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_all_methods(visibility: :public)
        names = select_instance_methods(visibility: visibility, include_inherited: true)
        benchmark_methods(*names)
      end

      # Benchmarks non-inherited instance methods
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_instance_methods(visibility: :public)
        names = select_instance_methods(visibility: visibility, include_inherited: false)
        benchmark_methods(*names)
      end

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

      # Benchmarks explicit class methods by name
      def benchmark_class_methods(*method_names)
        method_names.each do |method_name|
          wrap_class_method method_name do |start_time, result, method|
            end_time = Time.now
            class_benchmarked[method] = end_time - start_time
            result
          end
        end
      end

      # Benchmarks class methods defined only on this class (non-inherited)
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_own_class_methods(visibility: :public)
        names = select_class_methods(visibility: visibility, include_inherited: false)
        benchmark_class_methods(*names)
      end

      # Benchmarks class methods including inherited ones
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def benchmark_all_class_methods(visibility: :public)
        names = select_class_methods(visibility: visibility, include_inherited: true)
        benchmark_class_methods(*names)
      end
    end
  end
end
