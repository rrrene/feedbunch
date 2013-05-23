##
# This class has methods related to adding a feed to a folder

class FolderFeedAdd

  ##
  # Add a feed to a folder.
  #
  # Receives as arguments the id of the feed, the id of the folder and the user instance which is subscribed
  # to the feed and to which owns the folder.
  #
  # The folder must belong to the user, and the user must be subscribed to the feed. If any of these
  # conditions is not met, an ActiveRecord::RecordNotFound error is raised.
  #
  # If the feed was previously in another folder (owned by the same user), it is removed from that folder.
  # If there are no more feeds in that folder, it is deleted.
  #
  # Returns a hash with the following values:
  # - :feed => the feed which has been added to the folder
  # - :new_folder => the folder to which the feed has been added
  # - :old_folder => the folder (owned by this user) in which the feed was previously. This object may have already
  # been deleted from the database, if there were no more feeds in it. If the feed wasn't in any folder, this key is
  # not present in the hash

  def self.add_feed_to_folder(feed_id, folder_id, user)
    # Ensure the user is subscribed to the feed and the folder is owned by the user.
    feed = user.feeds.find feed_id
    folder = user.folders.find folder_id

    # Retrieve the current folder the feed is in, if any
    old_folder = feed.user_folder user

    Rails.logger.info "user #{user.id} - #{user.email} is adding feed #{feed.id} - #{feed.fetch_url} to folder #{folder.id} - #{folder.title}"
    folder.feeds << feed

    changes = {}
    changes[:new_folder] = folder.reload
    changes[:feed] = feed.reload
    changes[:old_folder] = old_folder if old_folder.present?

    return changes
  end

  ##
  # Create a new folder owned by the user, and add a feed to it.
  #
  # Receives as arguments the id of the feed, the title of the new folder and the user that will own the folder.
  #
  # If the user already has a folder with the same title, raises a FolderAlreadyExistsError.
  # If the user is not subscribed to the feed, raises an ActiveRecord::RecordNotFound error.
  #
  # If the feed was previously in another folder (owned by the same user), it is removed from that folder.
  # If there are no more feeds in that folder, it is deleted.
  #
  # Returns a hash with the following values:
  # - :new_folder => the newly created folder to which the feed has been added
  # - :old_folder => the folder (owned by this user) in which the feed was previously. This object may have already
  # been deleted from the database, if there were no more feeds in it. If the feed wasn't in any folder, this key is
  # not present in the hash

  def self.add_feed_to_new_folder(feed_id, folder_title, user)
    # Ensure that user is subscribed to the feed
    feed = user.feeds.find feed_id

    if user.folders.where(title: folder_title).present?
      Rails.logger.info "User #{user.id} - #{user.email} tried to create a new folder with title #{folder_title}, but it already has a folder with that title"
      raise FolderAlreadyExistsError.new
    end

    Rails.logger.info "Creating folder with title #{folder_title} for user #{user.id} - #{user.email}"
    folder = user.folders.create title: folder_title

    changes = user.add_feed_to_folder feed.id, folder.id
    # Only return the :old_folder, :new_folder keys
    return changes.except :feed
  end
end