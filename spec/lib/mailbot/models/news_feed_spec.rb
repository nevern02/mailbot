require 'spec_helper'

RSpec.describe Mailbot::Models::NewsFeed do
  let(:reader)  { Mailbot::RSS::RssReaderMock }
  let(:discord) { Mailbot::Discord::Connection.new }

  subject!(:feed) { described_class.create!(reader_class: reader.to_s) }

  before(:each) do
    allow(Mailbot).to receive_message_chain(:instance, :discord).and_return(discord)
  end

  after(:each) { Mailbot::Models::RssItem.destroy_all }

  after(:all) { described_class.destroy_all }

  describe '#refresh!' do
    context 'when the stories do not yet exist' do
      it 'saves the stories' do
        expect(feed.rss_items.count).to eq(0)

        feed.refresh!

        expect(feed.rss_items.count).to eq(reader.new.refresh!.length)
      end

      context 'when the timestamp is older than the latest recorded story' do
        before(:each) { Mailbot::Models::RssItem.create!(guid: 42, news_feed_id: feed.id, published_at: Time.now + 5.minutes) }

        it 'does NOT save the stories' do
          expect(feed.rss_items.count).to eq(1)

          feed.refresh!

          expect(feed.rss_items.count).to eq(1)
        end
      end
    end

    context 'when the stories already exist' do
      let(:items) { reader.new.refresh! }

      before(:each) do
        items.each do |item|
          Mailbot::Models::RssItem.create!(guid: item.guid, news_feed_id: feed.id)
        end
      end

      it 'does NOT save the stories' do
        expect(feed.rss_items.count).to eq(reader.new.refresh!.length)

        feed.refresh!

        expect(feed.rss_items.count).to eq(reader.new.refresh!.length)
      end
    end
  end

  it 'posts new messages to discord for each subscription' do
    feed.news_feed_subscriptions.create!(discord_channel_id: 42)
    feed.news_feed_subscriptions.create!(discord_channel_id: 43)

    expect(discord).to receive(:send_message).with('42', *any_args).twice
    expect(discord).to receive(:send_message).with('43', *any_args).twice

    feed.refresh_and_notify!
  end
end
