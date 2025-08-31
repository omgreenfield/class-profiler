# frozen_string_literal: true

RSpec.describe ClassProfiler::Memory do
  context 'with profile_methods for explicit method list' do
    let(:klass) do
      Class.new do
        include ClassProfiler::Memory

        def allocate_strings
          Array.new(50) { 'x' * 10 }
        end

        profile_methods :allocate_strings
      end
    end

    let(:obj) { klass.new }

    before { obj.allocate_strings }

    it 'records allocation deltas for the profiled method' do
      expect(obj.profiled_memory).to include(:allocate_strings)
      stats = obj.profiled_memory[:allocate_strings]
      expect(stats[:allocated_objects]).to be_a(Integer)
      expect(stats[:malloc_increase_bytes]).to be_a(Integer)
    end
  end

  context 'with profile_instance_methods in an inheritance hierarchy' do
    let(:parent) do
      Class.new do
        include ClassProfiler::Memory
        def parent_allocate = Array.new(10) { 'x' }
      end
    end

    let(:child) do
      Class.new(parent) do
        def child_allocate = Array.new(10) { 'y' }
        profile_instance_methods
      end
    end

    let(:obj) { child.new }

    before do
      obj.parent_allocate
      obj.child_allocate
    end

    it 'profiles only non-inherited methods' do
      expect(obj.profiled_memory).to include(:child_allocate)
      expect(obj.profiled_memory).not_to include(:parent_allocate)
    end
  end
end
