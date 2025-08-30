# frozen_string_literal: true

RSpec.describe ClassProfiler::Benchmark do
  it 'benchmarks specified methods and records elapsed time' do
    klass = Class.new do
      include ClassProfiler::Benchmark

      def fast = 1.+(1)
      def slow = sleep(0.002)

      benchmark_methods :fast, :slow
    end

    obj = klass.new
    obj.fast
    obj.slow

    expect(obj.benchmarked).to include(:fast, :slow)
    expect(obj.benchmarked[:slow]).to be > 0
  end

  it 'benchmarks only non-inherited instance methods' do
    parent = Class.new do
      include ClassProfiler::Benchmark
      def parent_method = 'p'
    end

    child = Class.new(parent) do
      def child_method = 'c'
      benchmark_instance_methods
    end

    obj = child.new
    obj.parent_method
    obj.child_method

    expect(obj.benchmarked).to include(:child_method)
    expect(obj.benchmarked).not_to include(:parent_method)
  end

  # NOTE: inherited-all behavior can vary with Ruby internals; covered by unit tests elsewhere
end
