# frozen_string_literal: true

RSpec.shared_examples 'records memory stats for expected methods' do
  it 'stores allocation deltas for each expected method' do
    expected_methods.each do |m|
      expect(profiled).to have_key(m)
      stats = profiled[m]
      expect(stats[:allocated_objects]).to be_a(Integer)
      expect(stats[:malloc_increase_bytes]).to be_a(Integer)
    end
  end
end
