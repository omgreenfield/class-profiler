# frozen_string_literal: true

require 'logger'

RSpec.describe ClassProfiler::Memory do
  context 'with track_memory for explicit method list' do
    let(:klass) do
      Class.new do
        include ClassProfiler::Memory

        def allocate_strings
          Array.new(50) { 'x' * 10 }
        end

        track_memory inherited: false, protected: false, private: false
      end
    end

    let(:obj) { klass.new }

    before { obj.allocate_strings }

    it 'records allocation deltas for the selected method and reports' do
      expect(obj.memory).to include(:allocate_strings)
      stats = obj.memory[:allocate_strings]
      expect(stats[:allocated_objects]).to be_a(Integer)
      expect(stats[:malloc_increase_bytes]).to be_a(Integer)
      obj.memory_report
    end

    it 'writes the memory report to the configured logger' do
      require 'stringio'
      io = StringIO.new
      logger = Logger.new(io)
      logger.level = Logger::INFO

      # attach logger via a wrapper class that includes Logging
      # attach logger to the klass via Logging
      klass_with_logging = Class.new(klass) do
        include ClassProfiler::Logging
      end
      obj = klass_with_logging.new
      klass_with_logging.profiler_logger = logger

      obj.memory_report
      expect(io.string).to include('Method | Objects | Bytes')
    end
  end

  context 'with inheritance selection' do
    let(:parent) do
      Class.new do
        include ClassProfiler::Memory
        def parent_allocate = Array.new(10) { 'x' }
      end
    end

    let(:child) do
      Class.new(parent) do
        def child_allocate = Array.new(10) { 'y' }
        track_memory inherited: false
      end
    end

    let(:obj) { child.new }

    before do
      obj.parent_allocate
      obj.child_allocate
    end

    it 'tracks only non-inherited methods' do
      expect(obj.memory).to include(:child_allocate)
      expect(obj.memory).not_to include(:parent_allocate)
    end
  end
end
