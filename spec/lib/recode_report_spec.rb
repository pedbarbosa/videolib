# frozen_string_literal: true

require_relative '../../lib/recode_report'

describe RecodeReport do
  subject(:test) { described_class.new(params) }

  let(:recode_report) { '/tmp/videolib_test.html' }
  let(:params) do
    {
      config: {
        'copy_override' => ['abc'],
        'recode_report' => recode_report,
        'recode_cp_target' => '/foo'
      },
      recode: [
        { file: 'a.mkv', size: 123 },
        { file: 'b.mkv', size: 456 }
      ]
    }
  end

  it 'fails if no params are provided' do
    expect { described_class.new }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1)')
  end

  describe 'try to generate a report' do
    it { expect(test.generate).to eq ["#{recode_report}.tmp"] }
  end
end
