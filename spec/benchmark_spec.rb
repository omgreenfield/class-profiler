# frozen_string_literal: true

RSpec.describe ClassProfiler::Benchmark do
  let(:benchmarked) { obj.benchmarked }

  context 'with benchmark_methods for explicit method list' do
    let(:klass) do
      Class.new do
        include ClassProfiler::Benchmark

        def fast = 1.+(1)
        def slow = sleep(0.002)

        benchmark_methods :fast, :slow
      end
    end

    let(:obj) { klass.new }

    before do
      obj.fast
      obj.slow
    end

    it 'records timings for explicit methods' do
      expect(benchmarked.keys).to include(:fast, :slow)
      expect(benchmarked[:fast]).to be_a(Numeric)
      expect(benchmarked[:slow]).to be_a(Numeric)
      expect(benchmarked[:fast]).to be >= 0
      expect(benchmarked[:slow]).to be >= 0
    end

    it 'measures slow >= fast to guard against flakiness' do
      expect(benchmarked[:slow]).to be >= benchmarked[:fast]
    end
  end

  context 'with benchmark_instance_methods in an inheritance hierarchy' do
    let(:parent) do
      Class.new do
        include ClassProfiler::Benchmark
        def parent_method = 'p'
      end
    end

    let(:child) do
      Class.new(parent) do
        def child_method = 'c'
        benchmark_instance_methods
      end
    end

    let(:obj) { child.new }

    before do
      obj.parent_method
      obj.child_method
    end

    it 'benchmarks only non-inherited methods' do
      # parent method was invoked but should not be wrapped when selecting non-inherited
      expect(benchmarked).not_to include(:parent_method)
      expect(benchmarked).to include(:child_method)
      expect(benchmarked[:child_method]).to be >= 0
    end
  end

  context 'with benchmark_all_methods including inherited methods' do
    let(:parent) do
      Class.new do
        include ClassProfiler::Benchmark
        def parent_method = 'p'

        protected

        def parent_protected = 'pp'

        private

        def parent_private = 'pv'
      end
    end

    let(:child) do
      Class.new(parent) do
        def child_method = 'c'

        protected

        def child_protected = 'cp'

        private

        def child_private = 'cv'
        benchmark_all_methods(visibility: :all)
      end
    end

    let(:obj) { child.new }

    it 'benchmarks inherited and child methods across visibilities' do
      obj.parent_method
      obj.send(:parent_protected)
      obj.send(:parent_private)
      obj.child_method
      obj.send(:child_protected)
      obj.send(:child_private)

      expect(benchmarked).to include(:child_method, :parent_method, :child_protected, :parent_protected,
                                     :child_private, :parent_private)
      expect(benchmarked.values).to all(be >= 0)
    end
  end

  context 'with class method benchmarking' do
    context 'explicit class methods' do
      let(:klass) do
        Class.new do
          include ClassProfiler::Benchmark

          def self.a = 1.+(1)
          def self.b = sleep(0.002)

          benchmark_class_methods :a, :b
        end
      end

      it 'records timings for class methods' do
        klass.a
        klass.b
        expect(klass.class_benchmarked).to include(:a, :b)
        expect(klass.class_benchmarked[:a]).to be >= 0
        expect(klass.class_benchmarked[:b]).to be >= 0
      end
    end

    context 'own vs inherited class methods with visibility selection' do
      let(:parent) do
        Class.new do
          include ClassProfiler::Benchmark
          def self.p_pub = 'pp'
          class << self
            protected

            def p_prot = 'prot'

            private

            def p_priv = 'priv'
          end
        end
      end

      let(:child) do
        Class.new(parent) do
          def self.c_pub = 'cp'
          class << self
            protected

            def c_prot = 'prot'

            private

            def c_priv = 'priv'
          end

          benchmark_own_class_methods(visibility: :all)
        end
      end

      it 'benchmarks only own class methods across visibilities' do
        child.c_pub
        child.send(:c_prot)
        child.send(:c_priv)

        expect(child.class_benchmarked).to include(:c_pub, :c_prot, :c_priv)
        expect(child.class_benchmarked).not_to include(:p_pub, :p_prot, :p_priv)
      end

      it 'benchmarks inherited class methods when requested' do
        child = Class.new(parent) do
          def self.c_pub = 'cp'
          benchmark_all_class_methods(visibility: :public)
        end

        child.p_pub
        child.c_pub

        expect(child.class_benchmarked).to include(:p_pub, :c_pub)
      end
    end
  end
end
