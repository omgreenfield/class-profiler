# frozen_string_literal: true

RSpec.describe ClassProfiler do
  it 'has a version number' do
    expect(ClassProfiler::VERSION).not_to be nil
  end

  it 'has a name' do
    expect(ClassProfiler::NAME).not_to be nil
  end
end
