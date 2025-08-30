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
      ##
      # Benchmarks instance methods and inherited instance methods
      def benchmark_all_methods
        benchmark_methods(*instance_methods)
      end

      ##
      # Benchmarks non-inherited instance methods
      def benchmark_instance_methods
        benchmark_methods(*instance_methods(false))
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
    end
  end
end
