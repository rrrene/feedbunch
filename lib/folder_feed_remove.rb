##
# This class has methods related to removing feeds from folders.

class FolderFeedRemove

  ##
  # Remove a feed from its current folder, ir any.
  #
  # Receives as argument the id of the feed and the user which owns the folder.
  #
  # A feed can only be in a single folder owned by a given user, so it's not necessary to pass the folder id
  # as an argument, it can be inferred from the user id and feed id.
  #
  # The user must be subscribed to the feed. Otherwise an ActiveRecord::RecordNotFound
  # error is raised.
  #
  # If after removing the feed there are no more feeds in the folder, it is deleted.
  #
  # Returns a boolean:
  # - true if the folder has not been deleted (it has more feeds in it)
  # - false if the folder has been deleted (it had no more feeds)

  def self.remove_feed_from_folder(feed_id, user)
    # Ensure that the user is subscribed to the feed
    feed = user.feeds.find feed_id

    folder = feed.user_folder user
    if folder.present?
      Rails.logger.info "user #{user.id} - #{user.email} is removing feed #{feed.id} - #{feed.fetch_url} from folder #{folder.id} - #{folder.title}"
      folder.feeds.delete feed
      return !folder.destroyed?
    else
      Rails.logger.info "user #{user.id} - #{user.email} is trying to remove feed #{feed.id} - #{feed.fetch_url} from its folder, but it's not in any folder"
      return true
    end

  end
end