require 'spec_helper'

describe FeedClient do
  before :each do
    @feed_client = FeedClient.new

    @feed = FactoryGirl.create :feed, title: 'Some feed title', url: 'http://some.feed.com'

    @feed_title = 'xkcd.com'
    @feed_url = 'http://xkcd.com/'

    @entry1 = FactoryGirl.build :entry
    @entry1.title = 'Silence'
    @entry1.url = 'http://xkcd.com/1199/'
    @entry1.summary = %{&lt;img src="http://imgs.xkcd.com/comics/silence.png" title="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time." alt="All music is just performances of 4'33&amp;quot; in studios where another band happened to be playing at the time."&gt;}
    @entry1.published = 'Mon, 15 Apr 2013 04:00:00 -0000'
    @entry1.guid = 'http://xkcd.com/1199/'

    @entry2 = FactoryGirl.build :entry
    @entry2.title = 'Geologist'
    @entry2.url = 'http://xkcd.com/1198/'
    @entry2.summary = %{&lt;img src="http://imgs.xkcd.com/comics/geologist.png" title="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;" alt="'It seems like it's still alive, Professor.' 'Yeah, a big one like this can keep running around for a few billion years after you remove the head.&amp;quot;"&gt;}
    @entry2.published = 'Fri, 12 Apr 2013 04:00:00 -0000'
    @entry2.guid = 'http://xkcd.com/1198/'

    @http_client = double 'restclient'
    @http_client.stub :get
    @feed_client.http_client = @http_client
  end

  it 'downloads the feed XML' do
    @http_client.should_receive(:get).with @feed.fetch_url, anything
    @feed_client.fetch @feed.id
  end

  context 'RSS 2.0 feeds' do

    before :each do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>#{@feed_title}</title>
    <link>#{@feed_url}</link>
    <description>xkcd.com: A webcomic of romance and math humor.</description>
    <language>en</language>
    <item>
      <title>#{@entry1.title}</title>
      <link>#{@entry1.url}</link>
      <description>#{@entry1.summary}</description>
      <pubDate>#{@entry1.published}</pubDate>
      <guid>#{@entry1.guid}</guid>
    </item>
    <item>
      <title>#{@entry2.title}</title>
      <link>#{@entry2.url}</link>
      <description>#{@entry2.summary}</description>
      <pubDate>#{@entry2.published}</pubDate>
      <guid>#{@entry2.guid}</guid>
    </item>
  </channel>
</rss>
FEED_XML

      feed_xml.stub(:headers).and_return {}
      @http_client.stub get: feed_xml
    end

    it 'fetches the right entries and saves them in the database' do
      @feed_client.fetch @feed.id
      @feed.reload
      @feed.entries.count.should eq 2

      entry1 = @feed.entries[0]
      entry1.title.should eq @entry1.title
      entry1.url.should eq @entry1.url
      entry1.author.should eq @entry1.author
      entry1.content.should eq @entry1.content
      entry1.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry1.published.should eq @entry1.published
      entry1.guid.should eq @entry1.guid

      entry2 = @feed.entries[1]
      entry2.title.should eq @entry2.title
      entry2.url.should eq @entry2.url
      entry2.author.should eq @entry2.author
      entry2.content.should eq @entry2.content
      entry2.summary.should eq CGI.unescapeHTML(@entry2.summary)
      entry2.published.should eq @entry2.published
      entry2.guid.should eq @entry2.guid
    end

    it 'updates entry if it is received again' do
      # Create an entry for feed @feed with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry = FactoryGirl.create :entry, feed_id: @feed.id, title: 'Original title',
                                 url: 'http://origina.url.com', author: 'Original author',
                                 content: 'Original content', summary: 'Original summary',
                                 published: DateTime.iso8601('2013-01-01T00:00:00'),
                                 guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid. This means it's an update to this entry.
      @feed_client.fetch @feed.id
      # After fetching, relevant fields should be updated with the values received in the XML
      entry.reload
      entry.feed_id.should eq @feed.id
      entry.title.should eq @entry1.title
      entry.url.should eq @entry1.url
      entry.author.should eq @entry1.author
      entry.content.should eq @entry1.content
      entry.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry.published.should eq @entry1.published
      entry.guid.should eq @entry1.guid
    end

    it 'retrieves the feed title and saves it in the database' do
      @feed_client.fetch @feed.id
      @feed.reload
      @feed.title.should eq @feed_title
    end

    it 'retrieves the feed URL and saves it in the database' do
      @feed_client.fetch @feed.id
      @feed.reload
      @feed.url.should eq @feed_url
    end
  end

  context 'Atom feeds' do

    before :each do
      feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@feed_title}</title>
  <link href="#{@feed_url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
  <entry>
    <title>#{@entry1.title}</title>
    <link href="#{@entry1.url}" rel="alternate" />
    <updated>#{@entry1.published}</updated>
    <id>#{@entry1.guid}</id>
    <summary type="html">#{@entry1.summary}</summary>
  </entry>
  <entry>
    <title>#{@entry2.title}</title>
    <link href="#{@entry2.url}" rel="alternate" />
    <updated>#{@entry2.published}</updated>
    <id>#{@entry2.guid}</id>
    <summary type="html">#{@entry2.summary}</summary>
  </entry>
</feed>
FEED_XML

      feed_xml.stub(:headers).and_return {}
      @http_client.stub get: feed_xml
    end

    it 'fetches the right entries and saves them in the database' do
      @feed_client.fetch @feed.id
      @feed.reload
      @feed.entries.count.should eq 2

      entry1 = @feed.entries[0]
      entry1.title.should eq @entry1.title
      entry1.url.should eq @entry1.url
      entry1.author.should eq @entry1.author
      entry1.content.should eq @entry1.content
      entry1.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry1.published.should eq @entry1.published
      entry1.guid.should eq @entry1.guid

      entry2 = @feed.entries[1]
      entry2.title.should eq @entry2.title
      entry2.url.should eq @entry2.url
      entry2.author.should eq @entry2.author
      entry2.content.should eq @entry2.content
      entry2.summary.should eq CGI.unescapeHTML(@entry2.summary)
      entry2.published.should eq @entry2.published
      entry2.guid.should eq @entry2.guid
    end

    it 'updates entry if it is received again' do
      # Create an entry for feed @feed with the same guid as @entry1 (which is not saved in the DB) but all other
      # fields with different values
      entry = FactoryGirl.create :entry, feed_id: @feed.id, title: 'Original title',
                                 url: 'http://origina.url.com', author: 'Original author',
                                 content: 'Original content', summary: 'Original summary',
                                 published: DateTime.iso8601('2013-01-01T00:00:00'),
                                 guid: @entry1.guid

      # XML that will be fetched contains an entry with the same guid. This means it's an update to this entry.
      @feed_client.fetch @feed.id
      # After fetching, relevant fields should be updated with the values received in the XML
      entry.reload
      entry.feed_id.should eq @feed.id
      entry.title.should eq @entry1.title
      entry.url.should eq @entry1.url
      entry.author.should eq @entry1.author
      entry.content.should eq @entry1.content
      entry.summary.should eq CGI.unescapeHTML(@entry1.summary)
      entry.published.should eq @entry1.published
      entry.guid.should eq @entry1.guid
    end

    it 'retrieves the feed title and saves it in the database' do
      @feed_client.fetch @feed.id
      @feed.reload
      @feed.title.should eq @feed_title
    end

    it 'retrieves the feed URL and saves it in the database' do
      @feed_client.fetch @feed.id
      @feed.reload
      @feed.url.should eq @feed_url
    end
  end

  context 'caching' do

    before :each do
      @feed_xml = <<FEED_XML
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en">
  <title>#{@feed_title}</title>
  <link href="#{@feed_url}" rel="alternate" />
  <id>http://xkcd.com/</id>
  <updated>2013-04-15T00:00:00Z</updated>
</feed>
FEED_XML

      @etag = "\"3648649162\""
      @last_modified = DateTime.now
      @headers = {etag: @etag, last_modified: @last_modified}
      @feed_xml.stub(:headers).and_return @headers
      @http_client.stub(:get).and_return @feed_xml
    end

    it 'saves etag and last-modified headers if they are in the response' do
      @feed_client.fetch @feed.id
      @feed.reload
      @feed.etag.should eq @etag
      @feed.last_modified.to_i.should eq @last_modified.to_i
    end

    it 'sets etag to nil in the database if the header is not present' do
      @feed = FactoryGirl.create :feed, etag:'some_etag'
      @feed.etag.should_not be_nil
      @headers = {last_modified: @last_modified}
      @feed_xml.stub(:headers).and_return @headers

      @feed_client.fetch @feed.id
      @feed.reload
      @feed.etag.should be_nil
    end

    it 'sets last-modified to nil in the database if the header is not present' do
      @feed = FactoryGirl.create :feed, last_modified: DateTime.now
      @feed.last_modified.should_not be_nil
      @headers = {etag: @etag}
      @feed_xml.stub(:headers).and_return @headers

      @feed_client.fetch @feed.id
      @feed.reload
      @feed.last_modified.should be_nil
    end

    it 'tries to cache data using an etag' do
      @headers = {etag: @etag}
      @feed_xml.stub(:headers).and_return @headers
      # Fetch the feed a first time, so the etag is saved
      @feed_client.fetch @feed.id

      # Next time the feed is fetched, the etag from the last time will be sent in the if-none-match header
      @feed.reload
      @http_client.should_receive(:get).with @feed.fetch_url, {if_none_match: @feed.etag}
      @feed_client.fetch @feed.id
    end

    it 'tries to cache data using last-modified' do
      @headers = {last_modified: @last_modified}
      @feed_xml.stub(:headers).and_return @headers
      # Fetch the feed a first time, so the last-modified is saved
      @feed_client.fetch @feed.id

      # Next time the feed is fetched, the last-modified from the last time will be sent in the if-modified-since header
      @feed.reload
      @http_client.should_receive(:get).with @feed.fetch_url, {if_modified_since: @feed.last_modified}
      @feed_client.fetch @feed.id
    end

    it 'tries to cache data using etag and last-modified if both are present' do
      # Fetch the feed a first time, so the last-modified is saved
      @feed_client.fetch @feed.id

      # Next time the feed is fetched, the last-modified from the last time will be sent in the if-modified-since header
      @feed.reload
      @http_client.should_receive(:get).with do |url, headers|
        url.should eq @feed.fetch_url
        headers.should include(if_none_match: @feed.etag)
        headers.should include(if_modified_since: @feed.last_modified)
      end
      @feed_client.fetch @feed.id
    end
  end
end