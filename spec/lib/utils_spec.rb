# frozen_string_literal: true

require_relative '../../lib/utils'

describe 'lib/utils tests' do
  it 'Test exit_with_msg' do
    message = 'abc'
    output = StringIO.new
    $stderr = output
    exit_with_msg(message)
  rescue SystemExit
    expect(output.string).to eq("Error: #{message}\n")
  end
end
