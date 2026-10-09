# frozen_string_literal: true

require_relative '../../lib/recode_report'

describe RecodeReport do
  subject(:test) { described_class.new(params) }

  let(:recode_report) { '/tmp/videolib_test.html' }
  let(:params) do
    {
      config: { 'copy_override' => ['Skipped'], 'recode_report' => recode_report },
      recode: [
        { file: 'a.mkv', show: 'Listed', size: 2 * 1024 * 1024 },
        { file: 'b.mkv', show: 'Listed', size: 3 * 1024 * 1024 },
        { file: 'c.mkv', show: 'Skipped', size: 7 * 1024 * 1024 }
      ]
    }
  end

  it 'fails if no params are provided' do
    expect { described_class.new }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1)')
  end

  describe 'try to generate a report' do
    it { expect(test.generate).to eq ["#{recode_report}.tmp"] }

    it 'leaves copy_override shows out of the rows and the totals', :aggregate_failures do
      test.generate
      report = File.read(recode_report)
      expect(report).to include('a.mkv', 'b.mkv', '2 file(s)', '<td class="right">5</td>')
      expect(report).not_to include('c.mkv')
    end
  end
end
