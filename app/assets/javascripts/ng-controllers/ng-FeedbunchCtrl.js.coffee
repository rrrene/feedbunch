########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'FeedbunchCtrl',
['$rootScope', '$scope', '$timeout', '$sce', 'feedsFoldersSvc', 'importStateSvc', 'exportStateSvc', 'timerFlagSvc',
'currentFeedSvc', 'currentFolderSvc', 'subscriptionSvc', 'readSvc', 'folderSvc', 'entrySvc', 'entriesPaginationSvc',
'findSvc', 'userDataSvc', 'userConfigSvc', 'openEntrySvc', 'unreadCountSvc', 'sidebarVisibleSvc', 'menuCollapseSvc',
'tooltipSvc', 'startPageSvc', 'jobStateSvc'
($rootScope, $scope, $timeout, $sce, feedsFoldersSvc, importStateSvc, exportStateSvc, timerFlagSvc,
currentFeedSvc, currentFolderSvc, subscriptionSvc, readSvc, folderSvc, entrySvc, entriesPaginationSvc,
findSvc, userDataSvc, userConfigSvc, openEntrySvc, unreadCountSvc, sidebarVisibleSvc, menuCollapseSvc,
tooltipSvc, startPageSvc, jobStateSvc)->

  #--------------------------------------------
  # APPLICATION INITIALIZATION
  #--------------------------------------------

  # By default sidebar is visible in smartphones and other small screens
  sidebarVisibleSvc.set true

  # Show Add Subscription button in this view
  $rootScope.show_feed_buttons = true

  # Initialize navbar tooltips
  tooltipSvc.navbar_tooltips()

  # Initialize footer tooltips
  tooltipSvc.footer_tooltips()

  # Initialize import alert tooltips
  tooltipSvc.import_state_tooltips()

  # Initialize export alert tooltips
  tooltipSvc.export_state_tooltips()

  # Load configuration for the current user.
  userConfigSvc.load_config()

  # Load data for the current user.
  userDataSvc.load_data()

  # Load folders and feeds via AJAX on startup
  feedsFoldersSvc.start_refresh_timer()

  # Load state of data export process for the current user
  exportStateSvc.load_data false

  # Load state of data import process for the current user
  importStateSvc.load_data false

  # Load job states via AJAX on startup
  jobStateSvc.load_data()

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'

  # Initialize collapsing menu in smartphones
  menuCollapseSvc.start()

  #--------------------------------------------
  # Show the start page
  #--------------------------------------------
  $scope.show_start_page = ->
    startPageSvc.show_start_page()
    return

  #--------------------------------------------
  # Unsubscribe from a feed
  #--------------------------------------------
  $scope.unsubscribe = ->
    subscriptionSvc.unsubscribe()
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Subscribe to a feed
  #--------------------------------------------
  $scope.subscribe = ->
    $("#subscribe-feed-popup").modal 'hide'
    subscriptionSvc.subscribe $scope.subscription_url
    $scope.subscription_url = null
    return

  #--------------------------------------------
  # Show all feeds (regardless of whether they have unread entries or not)
  # and all entries (regardless of whether they are read or not).
  #--------------------------------------------
  $scope.show_read_feeds_entries = ->
    feedsFoldersSvc.show_read()
    readSvc.read_entries_page()
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Show only unread entries and feeds with unread entries.
  #--------------------------------------------
  $scope.hide_read_feeds_entries = ->
    feedsFoldersSvc.hide_read()
    readSvc.read_entries_page()
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  $scope.remove_from_folder = ->
    folderSvc.remove_from_folder()
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  $scope.move_to_folder = (folder)->
    folderSvc.move_to_folder folder
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------
  $scope.move_to_new_folder = ()->
    $("#new-folder-popup").modal 'hide'
    folderSvc.move_to_new_folder $scope.new_folder_title
    $scope.new_folder_title = null
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Get the currently selected feed
  #--------------------------------------------
  $scope.get_current_feed = ->
    return currentFeedSvc.get()

  #--------------------------------------------
  # Set the currently selected feed
  #--------------------------------------------
  $scope.set_current_feed = (feed_id)->
    feed = findSvc.find_feed feed_id
    if feed?
      currentFeedSvc.set feed
      tooltipSvc.feed_title_tooltip()
      readSvc.read_entries_page()
      feedsFoldersSvc.load_feed feed_id
      menuCollapseSvc.close()
      $timeout ->
        sidebarVisibleSvc.set false
      , 300
    return

  #--------------------------------------------
  # Set the currently selected folder
  #--------------------------------------------
  $scope.set_current_folder = (folder)->
    currentFolderSvc.set folder
    readSvc.read_entries_page()
    feedsFoldersSvc.load_folder_feeds folder
    menuCollapseSvc.close()
    $timeout ->
      sidebarVisibleSvc.set false
    , 300
    return

  #--------------------------------------------
  # Load a page of entries for the currently selected feed or folder
  #--------------------------------------------
  $scope.read_entries_page = ->
    readSvc.read_entries_page()
    return

  #--------------------------------------------
  # Refresh a feed and load its unread entries
  #--------------------------------------------
  $scope.refresh_feed = ->
    readSvc.refresh_feed()
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Mark a single folder as open in the scope
  #--------------------------------------------
  $scope.toggle_open_folder = (folder)->
    readSvc.toggle_open_folder folder
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Toggle open/close for an entry. Mark it as read if opening.
  #--------------------------------------------
  $scope.toggle_open_entry = (entry)->
    entrySvc.toggle_open_entry entry
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Enable tooltips for an entry.
  #--------------------------------------------
  $scope.tooltips_entry = (entry)->
    tooltipSvc.entry_tooltips entry
    return

  #--------------------------------------------
  # Enable tooltips for a refresh feed job's state alert.
  #--------------------------------------------
  $scope.tooltips_refresh_job_state = (job_state)->
    tooltipSvc.refresh_job_state_tooltips job_state
    return

  #--------------------------------------------
  # Enable tooltips for a subscribe job's state alert.
  #--------------------------------------------
  $scope.tooltips_subscribe_job_state = (job_state)->
    tooltipSvc.subscribe_job_state_tooltips job_state
    return

  #--------------------------------------------
  # Function to decide if an entry should be displayed as open (return true) or closed (return false).
  #--------------------------------------------
  $scope.is_open = (entry)->
    openEntrySvc.is_open entry

  #--------------------------------------------
  # Mark all entries as read
  #--------------------------------------------
  $scope.mark_all_read = ->
    entrySvc.mark_all_read()
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Mark a single entry as unread
  #--------------------------------------------
  $scope.unread_entry = (entry)->
    entrySvc.unread_entry entry
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Mark a single entry as read
  #--------------------------------------------
  $scope.read_entry = (entry)->
    entrySvc.read_entry entry
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Return the title of the feed to which an entry belongs
  #--------------------------------------------
  $scope.entry_feed_title = (entry)->
    entrySvc.entry_feed_title entry

  #--------------------------------------------
  # Set the feed to which belongs the passed entry as the currently selected feed.
  # Also the passed entry is marked as unread, so that it's visible in the new list of entries.
  #--------------------------------------------
  $scope.set_current_entry_feed = (entry)->
    entrySvc.load_entry_feed entry
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Return the HTML content or summary of an entry, explicitly marked as trusted HTML for binding.
  #--------------------------------------------
  $scope.trustedEntryContent = (entry)->
    html = ''
    # Return the content if present; otherwise try to return the summary.
    if entry.content?.length > 0
      html = entry.content
    else if entry.summary?.length > 0
      html = entry.summary
    return $sce.trustAsHtml html


  #--------------------------------------------
  # Set a boolean flag in the root scope as false. The flag name must be passed as a string.
  # This is used to hide alerts when clicking on their X button.
  #--------------------------------------------
  $scope.reset_flag = (flag)->
    timerFlagSvc.reset flag
    return

  #--------------------------------------------
  # Count the number of unread entries in a folder
  #--------------------------------------------
  $scope.folder_unread_entries = (folder)->
    unreadCountSvc.folder_unread_entries folder

  #--------------------------------------------
  # Count the total number of unread entries in feeds
  #--------------------------------------------
  $scope.total_unread_entries = ->
    unreadCountSvc.total_unread_entries()

  #--------------------------------------------
  # Toggle a boolean in the root scope that indicates if the sidebar with feeds/folders is
  # visible (true) or the entries list is visible (false).
  #--------------------------------------------
  $scope.toggle_sidebar_visible = ->
    sidebarVisibleSvc.toggle()
    menuCollapseSvc.close()
    return

  #--------------------------------------------
  # Hide permanently the OPML import alert displayed in the start page
  #--------------------------------------------
  $scope.hide_import_alert = ->
    importStateSvc.hide_alert()
    return

  #--------------------------------------------
  # Hide permanently the OPML export alert displayed in the start page
  #--------------------------------------------
  $scope.hide_export_alert = ->
    exportStateSvc.hide_alert()
    return

  #--------------------------------------------
  # Return true if there are job states for which an alert should be displayed in the start page; false otherwise.
  #--------------------------------------------
  $scope.show_job_state_alerts = ->
    show_alerts = false
    if ($rootScope.refresh_feed_job_states? && $rootScope.refresh_feed_job_states?.length > 0)
      show_alerts = true
    else if ($rootScope.subscribe_job_states? && $rootScope.subscribe_job_states?.length > 0)
      show_alerts = true

    return show_alerts

  #--------------------------------------------
  # Permanently dismiss a refresh feed job alert from the start page
  #--------------------------------------------
  $scope.hide_refresh_job_alert = (job_state)->
    jobStateSvc.hide_refresh_job_alert(job_state)
    return

  #--------------------------------------------
  # Permanently dismiss a subscribe job alert from the start page
  #--------------------------------------------
  $scope.hide_subscribe_job_alert = (job_state)->
    jobStateSvc.hide_subscribe_job_alert(job_state)
    return

  #--------------------------------------------
  # Return a feed title, given its id.
  #--------------------------------------------
  $scope.feed_title = (feed_id)->
    if feed_id?
      feed = findSvc.find_feed feed_id
      if feed?
        return feed.title
      else
        # If the requested feed is not in the scope, try to load it from the server
        feedsFoldersSvc.load_feed feed_id
        return null

  #--------------------------------------------
  # Function to filter feeds in a given folder
  #--------------------------------------------
  $scope.feed_in_folder = (folder_id)->
    return (feed)->
      return folder_id == feed.folder_id

  #--------------------------------------------
  # Function to filter folders which should be visible. Returns a function that returns true if the passed folder
  # should be visible, false otherwise.
  #--------------------------------------------
  $scope.show_folder = (folder)->
    folderSvc.show_folder_filter folder

  #--------------------------------------------
  # Return a boolean indicating whether the "all subscriptions" link in a folder
  # should be show (if true) or not (if false).
  # The "all subscriptions" link is shown only when there is more than one visible feed in the folder.
  #--------------------------------------------
  $scope.show_all_subscriptions = (folder)->
    feeds = findSvc.find_folder_feeds folder
    return feeds?.length > 1

  #--------------------------------------------
  # Function to convert an entry's id to an integer, for filtering purposes
  #--------------------------------------------
  $scope.entry_int_id = (entry)->
    return parseInt entry.id

]