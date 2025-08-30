# frozen_string_literal: true

RSpec.describe ClassProfiler::Logging do
  context 'default logger' do
    it 'provides a default logger with WARN level' do
      klass = Class.new do
        include ClassProfiler
      end

      logger = klass.profiler_logger
      expect(logger).to be_a(Logger)
      expect(logger.level).to eq(Logger::WARN)
    end
  end

  context 'custom logger' do
    it 'allows setting and retrieving a custom logger via class and instance' do
      klass = Class.new do
        include ClassProfiler
      end

      custom = Logger.new($stderr)
      custom.level = Logger::INFO

      klass.profiler_logger = custom

      expect(klass.profiler_logger).to be(custom)
      expect(klass.new.profiler_logger).to be(custom)
    end
  end
end
