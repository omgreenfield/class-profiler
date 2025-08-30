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
    end
  end
end
