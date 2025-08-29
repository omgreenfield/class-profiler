# frozen_string_literal: true

RSpec.describe ClassProfiler do
  it 'has a version number' do
    expect(ClassProfiler::VERSION).not_to be nil
  end

  it 'has a name' do
    expect(ClassProfiler::NAME).not_to be nil
  end

  describe 'Benchmark integration' do
    it 'benchmarks specified methods and records elapsed time' do
      klass = Class.new do
        include ClassProfiler

        def fast; 1 + 1; end
        def slow; sleep 0.01; end

        benchmark_methods :fast, :slow
      end

      obj = klass.new
      obj.fast
      obj.slow

      expect(obj.benchmarked).to include(:fast, :slow)
      expect(obj.benchmarked[:slow]).to be > 0
    end

    it 'benchmarks only non-inherited instance methods when requested' do
      parent = Class.new do
        include ClassProfiler
        def parent_method; 'p'; end
      end

      child = Class.new(parent) do
        def child_method; 'c'; end
        benchmark_instance_methods
      end

      obj = child.new
      obj.parent_method
      obj.child_method

      expect(obj.benchmarked).to include(:child_method)
      expect(obj.benchmarked).not_to include(:parent_method)
    end
  end

  describe 'Memory profiling integration' do
    it 'profiles specified methods and records allocation deltas' do
      klass = Class.new do
        include ClassProfiler

        def allocate_strings
          Array.new(100) { "x" * 10 }
        end

        profile_methods :allocate_strings
      end

      obj = klass.new
      obj.allocate_strings

      expect(obj.profiled_memory).to include(:allocate_strings)
      stats = obj.profiled_memory[:allocate_strings]
      expect(stats[:allocated_objects]).to be >= 0
      expect(stats[:malloc_increase_bytes]).to be_a(Integer)
    end

    it 'profiles only non-inherited instance methods when requested' do
      parent = Class.new do
        include ClassProfiler
        def parent_allocate; Array.new(10) { 'x' }; end
      end

      child = Class.new(parent) do
        def child_allocate; Array.new(10) { 'y' }; end
        profile_instance_methods
      end

      obj = child.new
      obj.parent_allocate
      obj.child_allocate

      expect(obj.profiled_memory).to include(:child_allocate)
      expect(obj.profiled_memory).not_to include(:parent_allocate)
    end
  end
end
