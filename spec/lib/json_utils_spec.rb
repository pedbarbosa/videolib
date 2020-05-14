# frozen_string_literal: true

require_relative '../../lib/json_utils'

describe 'lib/json_utils.rb test' do
  let(:missing_file) { '/tmp/missing.json' }
  let(:test_file) { '/tmp/test.json' }
  let(:test_hash) { { 'a' => 'b' } }

  it 'write test' do
    expect { write_json(test_file, test_hash) }.not_to raise_error
  end

  before do
    @read_test = read_json(test_file)
  end

  it 'read test' do
    expect(@read_test).to eq(test_hash)
  end

  it 'missing test' do
    expect(read_json(missing_file)).to eq({})
  end
end
