# frozen_string_literal: true

require_relative '../../adapters/progressbar'

describe 'ProgressBar adapter functions' do
  describe '#progressbar_create' do
    it 'creates a progress bar with the correct format and total, hides output' do
      progressbar = progressbar_create('Processing', 100, ProgressBar::Outputs::Null)
      expect(progressbar).to be_a(ProgressBar::Base)
      expect(progressbar.total).to eq(100)
    end
  end

  describe '#progressbar_title' do
    it 'formats a title shorter than 19 characters' do
      title = 'Short Title'
      formatted_title = progressbar_title(title)
      expect(formatted_title).to eq("'Short Title'            ")
    end

    it 'truncates and appends ellipsis for a long title' do
      title = 'A very long title that exceeds 19 characters'
      formatted_title = progressbar_title(title)
      expect(formatted_title).to eq("'A very long title t ...'")
    end
  end

  describe '#progressbar_update' do
    let(:progressbar) { instance_double(ProgressBar::Base, title: '', increment: nil) }

    before do
      allow(progressbar).to receive(:title=)
      allow(progressbar).to receive(:increment)
    end

    it 'updates the progress bar title and increments the progress' do
      expect(progressbar).to receive(:title=).with("'A short title'          ")
      expect(progressbar).to receive(:increment)
      progressbar_update(progressbar, 'A short title')
    end
  end
end
