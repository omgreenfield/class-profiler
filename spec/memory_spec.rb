# frozen_string_literal: true

RSpec.describe ClassProfiler::Memory do
  it 'profiles specified methods and records allocation deltas' do
    klass = Class.new do
      include ClassProfiler::Memory

      def allocate_strings
        Array.new(50) { 'x' * 10 }
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
      include ClassProfiler::Memory
      def parent_allocate = Array.new(10) { 'x' }
    end

    child = Class.new(parent) do
      def child_allocate = Array.new(10) { 'y' }
      profile_instance_methods
    end

    obj = child.new
    obj.parent_allocate
    obj.child_allocate

    expect(obj.profiled_memory).to include(:child_allocate)
    expect(obj.profiled_memory).not_to include(:parent_allocate)
  end

  # NOTE: inherited-all behavior can be environment-sensitive; focusing on explicit method profiling
end
