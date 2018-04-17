$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'mailbot'
require 'timecop'
require 'vcr'

ActiveRecord::Base.logger.level = 1

Mailbot.configure do |config|
  config.log_file = nil
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

class DiscordMock
  attr_reader :buffer

  def initialize
    @buffer = []
  end

  def send_message(channel_id, message, tts = false, embed = nil)
    @buffer << {channel_id: channel_id, message: message}
    OpenStruct.new(id: '42')
  end
end

class RssReaderMock < Mailbot::RSS::Feed
  def refresh!
    @items = [
      Mailbot::RSS::FeedItem.new('Title 1', 'abc', '1', Time.now),
      Mailbot::RSS::FeedItem.new('Title 2', 'def', '2', Time.now)
    ]
  end
end
