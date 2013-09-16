########################################################
# AngularJS controllers file
########################################################

angular.module('feedbunch').controller 'FoldersCtrl',
['$rootScope', '$scope', '$http', '$timeout', '$filter', ($rootScope, $scope, $http, $timeout, $filter)->

  # Load folders and feeds via AJAX on startup
  $http.get('/folders.json').success (data)->
    $scope.folders = data

  $http.get('/feeds.json').success (data)->
    $scope.feeds = data

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
  # Store the currently selected feed in the global scope
  #--------------------------------------------

  $scope.set_current_feed = (feed)->
    $rootScope.current_feed = feed

  #--------------------------------------------
  # Unset the currently selected feed in the global scope
  #--------------------------------------------

  $scope.unset_current_feed = ->
    $rootScope.current_feed = null

  #--------------------------------------------
  # Unsubscribe from a feed
  #--------------------------------------------

  $scope.unsubscribe = ->
    # Delete feed model from the scope
    index = $scope.feeds.indexOf $rootScope.current_feed
    $scope.feeds.splice index, 1 if index != -1

    # Tell the model that no feed is currently selected.
    # Before deleting from the global scope, save some data we'll need later
    path = "/feeds/#{$rootScope.current_feed.id}.json"
    unread_entries = $rootScope.current_feed.unread_entries
    folder_id = $rootScope.current_feed.folder_id

    $rootScope.current_feed = null

    # Update folders
    find_folder('all').unread_entries -= unread_entries
    folder = find_folder folder_id
    if folder != null
      # Remove folder if it's empty
      if find_folder_feeds(folder_id).length == 0
        index = $scope.folders.indexOf folder
        $scope.folders.splice index, 1 if index != -1
      # Otherwise update unread entries in folder
      else
        folder.unread_entries -= unread_entries

    $http.delete(path).error ->
      # Show alert
      $scope.error_unsubscribing = true
      # Close alert after 5 seconds
      $timeout ->
        $scope.error_unsubscribing = false
      , 5000

  #--------------------------------------------
  # Subscribe to a feed
  #--------------------------------------------

  $scope.subscribe = ->
    # Clear input, close modal
    $("#subscribe-feed-popup").modal 'hide'

    if $scope.subscription_url
      $http.post('/feeds.json', feed:{url: $scope.subscription_url}).success (data)->
        $scope.feeds.push data
      .error (data, status)->
        # Show alert
        if status == 304
          $scope.error_already_subscribed = true
          # Close alert after 5 seconds
          $timeout ->
            $scope.error_already_subscribed = false
          , 5000
        else
          $scope.error_subscribing = true
          # Close alert after 5 seconds
          $timeout ->
            $scope.error_subscribing = false
          , 5000
    $scope.subscription_url = null

  #--------------------------------------------
  # Return a folder object given its id
  #--------------------------------------------

  find_folder = (id)->
    if id == 'none'
      return null
    else
      folders = $filter('filter') $scope.folders, {id: id}
      return folders[0]

  #--------------------------------------------
  # Return an array of feeds in a folder given the folder id
  #--------------------------------------------

  find_folder_feeds = (folder_id)->
    return $filter('filter') $scope.feeds, {folder_id: folder_id}

]