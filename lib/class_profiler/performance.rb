# frozen_string_literal: true

module ClassProfiler
  module Performance
    def self.included(base)
      base.extend(ClassMethods)
      # Ensure the including class has access to wrap_method
      base.extend(Methods::ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def performance
        @performance ||= {}
      end

      # Prints all performance-measured instance methods and the time taken per method (seconds)
      #
      # @param include_zero [Boolean] include methods with 0.0s measurements
      # @param sort_index [Integer] 0 for method, 1 for time, 2 for total
      #
      # @return [Hash]
      def performance_report(include_zero: false, sort_index: 1)
        headers = %w[Method Time Total]
        entries = performance.map do |method, values|
          if values.is_a?(Hash)
            [method, values[:time], values[:total]]
          else
            [method, values, values]
          end
        end
        print_report(entries, headers: headers, include_zero: include_zero, sort_index: sort_index)
      end
    end

    module ClassMethods
      include Methods::ClassMethods

      # Unified API to select and track instance methods' performance
      #
      # @param inherited [Boolean] include inherited instance methods
      # @param public [Boolean] include public methods
      # @param protected [Boolean] include protected methods
      # @param private [Boolean] include private methods
      def track_performance(inherited: false, public: true, protected: true, private: true)
        include_public = binding.local_variable_get(:public)
        include_protected = binding.local_variable_get(:protected)
        include_private = binding.local_variable_get(:private)

        names = []
        names |= select_instance_methods(visibility: :public, include_inherited: inherited) if include_public
        names |= select_instance_methods(visibility: :protected, include_inherited: inherited) if include_protected
        names |= select_instance_methods(visibility: :private, include_inherited: inherited) if include_private
        measure_performance_for_methods(*names)
      end

      # Measures non-inherited instance methods
      #
      # @param visibility [Symbol] :public, :protected, :private, :all
      def performance_instance_methods(visibility: :public)
        names = select_instance_methods(visibility: visibility, include_inherited: false)
        performance_methods(*names)
      end

      # Records how long each method call takes and saves it to `performance` hash
      #
      # @param method_names [Array<Symbol>] the names of the methods to measure
      private def measure_performance_for_methods(*method_names)
        method_names.each do |method_name|
          wrap_method method_name do |original, *args, &block|
            start_time = Time.now
            result = original.bind(self).call(*args, &block)
            end_time = Time.now
            duration = end_time - start_time
            performance[method_name] ||= { total: 0 }
            performance[method_name][:total] += duration
            performance[method_name][:time] = duration
            result
          end
        end
      end
    end
  end
end


