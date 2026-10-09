# frozen_string_literal: true

require 'tmpdir'
require_relative '../../lib/json_utils'

describe 'lib/json_utils.rb test' do
  let(:test_dir) { Dir.mktmpdir }
  let(:test_file) { "#{test_dir}/test.json" }
  let(:test_hash) { { 'a' => 'b' } }

  after { FileUtils.rm_rf(test_dir) }

  it 'reads back what it writes' do
    write_json(test_file, test_hash)
    expect(read_json(test_file)).to eq(test_hash)
  end

  it 'creates the directory it writes to' do
    write_json("#{test_dir}/new/test.json", test_hash)
    expect(read_json("#{test_dir}/new/test.json")).to eq(test_hash)
  end

  it 'reports an interrupt instead of raising it' do
    allow(File).to receive(:write).and_raise(Interrupt)
    expect { write_json(test_file, test_hash) }.to output(/Caught an interrupt request/).to_stdout
  end

  it 'reads a missing file as empty' do
    expect(read_json("#{test_dir}/missing.json")).to eq({})
  end
end
