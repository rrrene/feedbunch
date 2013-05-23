require 'fetched_entries'

##
# Class to parse a fetched feed.

class FeedParser

  ##
  # Try to parse an HTTP response as a feed (RSS, Atom or other formats supported by Feedzirra).
  #
  # If successful:
  # - saves in the database the title and URL for the feed.
  # - saves in the database the etag and last-modified headers (to be used the next time the feed is fetched).
  # - saves the fetched feed entries in the database.
  #
  # Any errors raised are bubbled to be handled higher up the call chain. In particular, if the response being parsed
  # is not a feed, it's likely that it's an HTML webpage, possibly with feed autodiscovery enabled. In this case
  # this function will raise an error and it's the responability of the calling function to capture this error and
  # handle feed autodiscovery on the HTML.
  #
  # Receives as arguments the feed object corresponding to the feed being fetched and the response to be parsed.
  #
  # Returns the updated feed object.

  def self.parse_feed(feed, feed_response)
    feed_parsed = Feedzirra::Feed.parse feed_response
    Rails.logger.info "Correctly parsed feed from url #{feed.fetch_url}"

    # Save the feed title and url.
    # Warning: don't confuse url (the url of the website generating the feed) with fetch_url (the url from which the
    # XML of the feed is fetched).
    Rails.logger.info "Fetched from: #{feed.fetch_url} - title: #{feed_parsed.title} - url: #{feed_parsed.url}"
    feed.title = feed_parsed.title
    feed.url = feed_parsed.url

    # Save the etag and last_modified headers. If one of these headers is not present, save a null in the database.
    if feed_response.headers.present?
      Rails.logger.info "HTTP headers in the response from #{feed.fetch_url} - etag: #{feed_response.headers[:etag]} - last-modified: #{feed_response.headers[:last_modified]}"
      feed.etag = feed_response.headers[:etag]
      feed.last_modified = feed_response.headers[:last_modified]
    end

    # Save entries in the database
    FetchedEntries.save_or_update_entries feed, feed_parsed.entries

    feed.save!
    return feed
  end
end