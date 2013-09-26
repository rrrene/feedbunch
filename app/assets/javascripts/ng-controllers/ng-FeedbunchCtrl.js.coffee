########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'FeedbunchCtrl',
['$rootScope', '$scope', '$http', '$timeout', '$filter', 'feedsFoldersSvc', 'importStatusSvc', 'timerFlagSvc',
'currentFeedSvc', 'currentFolderSvc', 'openEntrySvc','openFolderSvc', 'subscriptionSvc', 'readSvc', 'findSvc',
'folderSvc',
($rootScope, $scope, $http, $timeout, $filter, feedsFoldersSvc, importStatusSvc, timerFlagSvc,
currentFeedSvc, currentFolderSvc, openEntrySvc, openFolderSvc, subscriptionSvc, readSvc, findSvc,
folderSvc)->

  # Load folders and feeds via AJAX on startup
  feedsFoldersSvc.load_data()

  # Load status of data import process for the current user
  importStatusSvc.load_data false

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'

  #--------------------------------------------
  # Show the start page
  #--------------------------------------------
  $scope.show_start_page = ->
    currentFeedSvc.unset()
    $rootScope.loading_entries = false

  #--------------------------------------------
  # Unsubscribe from a feed
  #--------------------------------------------
  $scope.unsubscribe = ->
    subscriptionSvc.unsubscribe()

  #--------------------------------------------
  # Subscribe to a feed
  #--------------------------------------------
  $scope.subscribe = ->
    $("#subscribe-feed-popup").modal 'hide'
    subscriptionSvc.subscribe $scope.subscription_url
    $scope.subscription_url = null

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  $scope.remove_from_folder = ->
    folderSvc.remove_from_folder()

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  $scope.move_to_folder = (folder)->
    folderSvc.move_to_folder folder

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------
  $scope.move_to_new_folder = ()->
    $("#new-folder-popup").modal 'hide'
    folderSvc.move_to_new_folder $scope.new_folder_title
    $scope.new_folder_title = null

  #--------------------------------------------
  # Load a feed's unread entries
  #--------------------------------------------
  $scope.read_feed = (feed)->
    readSvc.read_feed feed

  #--------------------------------------------
  # Load a folder's unread entries
  #--------------------------------------------
  $scope.read_folder = (folder)->
    readSvc.read_folder folder

  #--------------------------------------------
  # Load all of a feed's entries regardless of state
  #--------------------------------------------
  $scope.read_all_entries = ->
    readSvc.read_feed_all()

  #--------------------------------------------
  # Refresh a feed and load its unread entries
  #--------------------------------------------
  $scope.refresh_feed = ->
    readSvc.refresh_feed()

  #--------------------------------------------
  # Mark a single entry as read
  #--------------------------------------------
  $scope.read_entry = (entry)->
    if openEntrySvc.get() == entry
      # User is closing the open entry, do nothing
      openEntrySvc.unset()
    else
      openEntrySvc.set entry
      if !entry.read
        # User is opening an unread entry, mark it as read
        change_entries_state [entry], true

  #--------------------------------------------
  # Mark a single folder as open in the scope
  #--------------------------------------------
  $scope.open_folder = (folder)->
    if openFolderSvc.get() == folder
      # User is closing the open folder
      openFolderSvc.unset()
    else
      openFolderSvc.set folder

  #--------------------------------------------
  # Mark all entries as read
  #--------------------------------------------
  $scope.mark_all_read = ->
    change_entries_state $rootScope.entries, true

  #--------------------------------------------
  # Mark a single entry as unread
  #--------------------------------------------
  $scope.unread_entry = ->
    if openEntrySvc.get().read
      change_entries_state [openEntrySvc.get()], false

  #--------------------------------------------
  # Mark an array of entries as read or unread.
  # Receives as arguments an array of entries and a boolean indicating whether to mark
  # them as read (true) or unread (false).
  #--------------------------------------------
  change_entries_state = (entries, read)->
    # Mark entries as read or unread in the model
    for entry in entries
      entry.read = read
      entry.changing_state = true

    # Get array of IDs for the entries
    entry_ids = entries.map (entry) -> entry.id

    if read
      state = "read"
      update_unread_count entries, false
    else
      state = "unread"
      update_unread_count entries, true

    $http.put("/entries/update.json", entries: {ids: entry_ids, state: state})
    .success ->
      for entry in entries
        entry.changing_state = false
    .error ->
      # Show alert
      $rootScope.error_changing_entry_state = true
      # Close alert after 5 seconds
      $timeout ->
        $rootScope.error_changing_entry_state = false
      , 5000

  #--------------------------------------------
  # Increment or decrement the count of unread entries in feeds corresponding to the passed entries.
  # Receives as argument an array of entries and a boolean indicating whether to
  # increment (true) or decrement (false) the count.
  #--------------------------------------------
  update_unread_count = (entries, increment)->
    if currentFeedSvc.get()
      # if current_feed has value, all entries belong to the same feed which simplifies things
      if increment
        currentFeedSvc.get().unread_entries += entries.length
      else
        currentFeedSvc.get().unread_entries -= entries.length
    else
      # if current_feed has null value, each entry can belong to a different feed
      # we process each entry individually
      for entry in entries
        feed = findSvc.find_feed entry.feed_id
        if increment
          feed.unread_entries += 1
        else
          feed.unread_entries -= 1

  #--------------------------------------------
  # Function to filter feeds in a given folder
  #--------------------------------------------
  $scope.feed_in_folder = (folder)->
    return (feed)->
      if folder.id == 'all'
        return true
      else
        return folder.id == feed.folder_id

  #--------------------------------------------
  # Function to convert an entry's id to an integer, for filtering purposes
  #--------------------------------------------
  $scope.entry_int_id = (entry)->
    return parseInt entry.id

]