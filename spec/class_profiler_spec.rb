# frozen_string_literal: true

RSpec.describe ClassProfiler do
  it 'has a version number' do
    expect(ClassProfiler::VERSION).not_to be nil
  end

  it 'has a name' do
    expect(ClassProfiler::NAME).not_to be nil
  end

  describe 'Benchmark integration' do
    context 'with explicit methods' do
      let(:klass) do
        Class.new do
          include ClassProfiler

          def fast = 1.+(1)
          def slow = sleep(0.002)

          benchmark_methods :fast, :slow
        end
      end

      let(:obj) { klass.new }

      before do
        obj.fast
        obj.slow
      end

      it 'records timings for both methods and slow >= fast' do
        expect(obj.benchmarked.keys).to include(:fast, :slow)
        expect(obj.benchmarked[:fast]).to be >= 0
        expect(obj.benchmarked[:slow]).to be >= obj.benchmarked[:fast]
      end
    end

    context 'with inheritance and non-inherited selection' do
      let(:parent) do
        Class.new do
          include ClassProfiler
          def parent_method = 'p'
        end
      end

      let(:child) do
        Class.new(parent) do
          def child_method = 'c'
          benchmark_instance_methods
        end
      end

      it 'includes only child methods' do
        obj = child.new
        obj.parent_method
        obj.child_method

        expect(obj.benchmarked).to include(:child_method)
        expect(obj.benchmarked).not_to include(:parent_method)
      end
    end
  end

  describe 'Memory profiling integration' do
    context 'with explicit methods' do
      let(:klass) do
        Class.new do
          include ClassProfiler

          def allocate_strings
            Array.new(100) { 'x' * 10 }
          end

          profile_methods :allocate_strings
        end
      end

      it 'records allocation deltas' do
        obj = klass.new
        obj.allocate_strings

        expect(obj.profiled_memory).to include(:allocate_strings)
        stats = obj.profiled_memory[:allocate_strings]
        expect(stats[:allocated_objects]).to be >= 0
        expect(stats[:malloc_increase_bytes]).to be_a(Integer)
      end
    end

    context 'with inheritance and non-inherited selection' do
      let(:parent) do
        Class.new do
          include ClassProfiler
          def parent_allocate = Array.new(10) { 'x' }
        end
      end

      let(:child) do
        Class.new(parent) do
          def child_allocate = Array.new(10) { 'y' }
          profile_instance_methods
        end
      end

      it 'includes only child methods' do
        obj = child.new
        obj.parent_allocate
        obj.child_allocate

        expect(obj.profiled_memory).to include(:child_allocate)
        expect(obj.profiled_memory).not_to include(:parent_allocate)
      end
    end
  end
end
