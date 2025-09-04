# frozen_string_literal: true

require 'logger'

RSpec.describe ClassProfiler::Performance do
  describe '#track_performance' do
    let(:klass) do
      Class.new do
        include ClassProfiler::Performance
        include ClassProfiler::Logging

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

    it 'records timings for selected methods' do
      expect(obj.performance.keys).to include(:fast, :slow)
      expect(obj.performance[:fast][:time]).to be_a(Numeric)
      expect(obj.performance[:slow][:time]).to be_a(Numeric)
      expect(obj.performance[:fast][:time]).to be >= 0
      expect(obj.performance[:slow][:time]).to be >= 0
    end

    it 'measures slow >= fast to guard against flakiness' do
      expect(obj.performance[:slow][:time]).to be >= obj.performance[:fast][:time]
    end

    it 'writes a tabular report via logger' do
      require 'stringio'
      io = StringIO.new
      logger = Logger.new(io)
      logger.level = Logger::INFO
      klass.profiler_logger = logger

      obj.performance_report
      expect(io.string).to match(/Method \| Time\s+\| Total/)
    end
  end

  describe 'inheritance selection with track_performance' do
    let(:parent) do
      Class.new do
        include ClassProfiler::Performance
        def parent_method = 'p'
      end
    end

    let(:child) do
      Class.new(parent) do
        def child_method = 'c'
        track_performance inherited: false
      end
    end

    it 'tracks only non-inherited methods by default' do
      obj = child.new
      obj.parent_method
      obj.child_method

      expect(obj.performance).to include(:child_method)
      expect(obj.performance).not_to include(:parent_method)
    end
  end
end
