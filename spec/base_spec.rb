# frozen_string_literal: true

require_relative '../lib/base'

describe 'lib/base.rb test' do
  it 'Test empty @episodes in process_read function' do
    expect(process_read([])).to eql nil
  end
end
