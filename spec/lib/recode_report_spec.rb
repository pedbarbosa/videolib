# frozen_string_literal: true

require_relative '../../lib/recode_report'

describe RecodeReport do
  it 'should fail if no params are provided' do
    RecodeReport.new
  rescue ArgumentError => e
    expect(e.message).to eq('wrong number of arguments (given 0, expected 1)')
  end

  recode_report = '/tmp/videolib_test.html'
  params = {
    config: {
      'copy_override' => ['abc'],
      'recode_report' => recode_report,
      'recode_cp_target' => '/foo'
    },
    recode: [['a', 'b', 'c', 'x', 1], ['e', 'f', 'g', 'h', 2]]
  }

  subject(:test) { described_class.new(params) }

  describe 'try to generate a report' do
    it { expect(test.generate).to eq ["#{recode_report}.tmp"] }
  end
end
