# frozen_string_literal: true

RSpec.describe ClassProfiler::Methods do
  describe '#select_instance_methods' do
    it 'selects only own public methods when include_inherited: false' do
      klass = Class.new do
        include ClassProfiler::Methods
        def a = 'a'
        protected def b = 'b'
        private def c = 'c'
      end

      names = klass.select_instance_methods(visibility: :public, include_inherited: false)
      expect(names).to include(:a)
      expect(names).not_to include(:b, :c)
    end

    it 'selects own and inherited methods when include_inherited: true' do
      parent = Class.new do
        include ClassProfiler::Methods
        def p = 'p'
      end
      child = Class.new(parent) do
        def c = 'c'
      end

      names = child.select_instance_methods(visibility: :public, include_inherited: true)
      expect(names).to include(:p, :c)
    end

    it 'respects :all visibility' do
      klass = Class.new do
        include ClassProfiler::Methods
        def a = 'a'
        protected def b = 'b'
        private def c = 'c'
      end

      names = klass.select_instance_methods(visibility: :all, include_inherited: false)
      expect(names).to include(:a, :b, :c)
    end
  end

  describe '#select_class_methods' do
    it 'selects only own public class methods' do
      klass = Class.new do
        include ClassProfiler::Methods
        def self.a = 'a'
        class << self
          protected def b = 'b'
          private def c = 'c'
        end
      end

      names = klass.select_class_methods(visibility: :public, include_inherited: false)
      expect(names).to include(:a)
      expect(names).not_to include(:b, :c)
    end

    it 'includes inherited when requested' do
      parent = Class.new do
        include ClassProfiler::Methods
        def self.p = 'p'
      end
      child = Class.new(parent)

      names = child.select_class_methods(visibility: :public, include_inherited: true)
      expect(names).to include(:p)
    end

    it 'respects :all visibility' do
      klass = Class.new do
        include ClassProfiler::Methods
        def self.a = 'a'
        class << self
          protected def b = 'b'
          private def c = 'c'
        end
      end

      names = klass.select_class_methods(visibility: :all, include_inherited: false)
      expect(names).to include(:a, :b, :c)
    end
  end

  describe '#wrap_class_method' do
    it 'wraps a class method and yields timing info to the wrapper' do
      klass = Class.new do
        include ClassProfiler::Methods
        def self.a = 1.+(1)
      end

      timings = {}
      klass.wrap_class_method(:a) do |start_time, result, method_name|
        timings[method_name] = Time.now - start_time
        result
      end

      expect(klass.a).to eq(2)
      expect(timings.keys).to include(:a)
      expect(timings[:a]).to be >= 0
    end
  end
end
