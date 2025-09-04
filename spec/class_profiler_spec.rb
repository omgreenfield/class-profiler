# frozen_string_literal: true

RSpec.describe ClassProfiler do
  it 'has a version number' do
    expect(ClassProfiler::VERSION).not_to be nil
  end

  it 'has a name' do
    expect(ClassProfiler::NAME).not_to be nil
  end

  describe 'Performance integration' do
    context 'with explicit methods' do
      let(:klass) do
        Class.new do
          include ClassProfiler

          def fast = 1.+(1)
          def slow = sleep(0.002)

          track_performance
        end
      end

      let(:obj) { klass.new }

      before do
        obj.fast
        obj.slow
      end

      it 'records timings for both methods and slow >= fast' do
        expect(obj.performance.keys).to include(:fast, :slow)
        expect(obj.performance[:fast][:time]).to be >= 0
        expect(obj.performance[:slow][:time]).to be >= obj.performance[:fast][:time]
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
          track_performance inherited: false
        end
      end

      it 'includes only child methods' do
        obj = child.new
        obj.parent_method
        obj.child_method

        expect(obj.performance).to include(:child_method)
        expect(obj.performance).not_to include(:parent_method)
      end
    end
  end

  describe 'Memory tracking integration' do
    context 'with explicit methods' do
      let(:klass) do
        Class.new do
          include ClassProfiler

          def allocate_strings
            Array.new(100) { 'x' * 10 }
          end

          track_memory inherited: false, protected: false, private: false
        end
      end

      it 'records allocation deltas' do
        obj = klass.new
        obj.allocate_strings

        expect(obj.memory).to include(:allocate_strings)
        stats = obj.memory[:allocate_strings]
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
          track_memory inherited: false
        end
      end

      it 'includes only child methods' do
        obj = child.new
        obj.parent_allocate
        obj.child_allocate

        expect(obj.memory).to include(:child_allocate)
        expect(obj.memory).not_to include(:parent_allocate)
      end
    end
  end
end
