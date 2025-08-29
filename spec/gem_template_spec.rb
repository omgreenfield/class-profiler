# frozen_string_literal: true

RSpec.describe GemTemplate do
  it 'has a version number' do
    expect(GemTemplate::VERSION).not_to be nil
  end

  it 'has a name' do
    expect(GemTemplate::NAME).not_to be nil
  end
end
