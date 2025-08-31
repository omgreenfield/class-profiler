# frozen_string_literal: true

module ClassProfiler
  module Logging
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def profiler_logger
        self.class.profiler_logger
      end
    end

    module ClassMethods
      # Simple fan-out logger that forwards to multiple underlying loggers
      class MultiLogger
        def initialize(*loggers)
          @loggers = loggers.compact
        end

        def add(severity, message = nil, progname = nil)
          @loggers.each { |l| l.add(severity, message, progname) }
        end

        def level=(lvl)
          @loggers.each { |l| l.level = lvl }
        end

        def level
          @loggers.map(&:level).min || Logger::INFO
        end
      end

      def profiler_logger
        @profiler_logger ||= begin
          require 'logger'
          logger = Logger.new($stdout)
          logger.level = Logger::WARN
          logger
        end
      end

      def profiler_logger=(logger)
        @profiler_logger = logger
      end

      # Configure logging to stdout
      def enable_profiler_logging_to_stdout(level: Logger::INFO)
        require 'logger'
        self.profiler_logger = Logger.new($stdout).tap { |l| l.level = level }
      end

      # Configure logging to a file, optionally also to stdout
      def enable_profiler_logging_to_file(path, level: Logger::INFO, shift_age: 0, shift_size: 1_048_576, also_stdout: false)
        require 'logger'
        file_logger = Logger.new(path, shift_age, shift_size)
        file_logger.level = level
        self.profiler_logger = if also_stdout
                                  stdout_logger = Logger.new($stdout)
                                  stdout_logger.level = level
                                  MultiLogger.new(file_logger, stdout_logger)
                                else
                                  file_logger
                                end
      end
    end
  end
end
