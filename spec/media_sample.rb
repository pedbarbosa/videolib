# frozen_string_literal: true

MEDIA_SAMPLE_PATH = File.expand_path('fixtures/sample.mkv', __dir__)

def media_sample
  { show: 'test', width: 320, height: 240, size: 3836,
    codec: 'V_MPEG4/ISO/AVC',
    mtime: File.mtime(MEDIA_SAMPLE_PATH).to_i }
end
