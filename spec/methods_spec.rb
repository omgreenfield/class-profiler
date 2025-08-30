# frozen_string_literal: true

RSpec.describe ClassProfiler::Methods do
  it 'wraps a method and yields the original UnboundMethod to a wrapper executed in instance context' do
    klass = Class.new do
      include ClassProfiler::Methods

      def greet(name)
        "hi #{name}"
      end

      wrap_method :greet do |original, *args|
        # Executed in instance context; we can bind and call the original
        original.bind(self).call(*args).upcase
      end
    end

    expect(klass.new.greet('matt')).to eq('HI MATT')
  end

  it 'supports custom alias prefix for the wrapped original' do
    klass = Class.new do
      include ClassProfiler::Methods

      def add(arg1, arg2)
        arg1 + arg2
      end

      wrap_method :add, prefix: 'wrapped_' do |original, *args|
        # Call via bound original and rely on separate assertion after call
        original.bind(self).call(*args) * 2
      end
    end

    instance = klass.new
    expect(instance.add(2, 3)).to eq(10)
    expect(instance.public_send(:wrapped_add, 2, 3)).to eq(5)
  end
end
