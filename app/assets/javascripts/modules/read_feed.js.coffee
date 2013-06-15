#= require ./alert_hiding
#= require ./shared_functions

window.Openreader ||= {}

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Load unread feed entries when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("body").on "click", "[data-sidebar-feed]", ->
    set_global_variables(this)
    mark_folder_in_dropdown()
    show_feed_title this
    Openreader.loading_entries this

    # Load the entries via Ajax
    $.get(Openreader.current_feed_path, null, insert_entries)
      .fail (xhr, textStatus, errorThrown) ->
        Openreader.entries_loaded(Openreader.current_feed_id)
        if xhr.status == 404
          Openreader.alertTimedShowHide $("#no-entries")
        else
          Openreader.alertTimedShowHide $("#problem-loading")

  #-------------------------------------------------------
  # Load read and unread feed entries when clicking on the "Show read entries" button
  #-------------------------------------------------------
  $("body").on "click", "#show-read-button", ->
    if $(this).hasClass("disabled") == false
      Openreader.loading_entries this
      # Load the entries via Ajax
      $.get(Openreader.current_feed_path, {include_read: true}, insert_entries)
        .fail (xhr, textStatus, errorThrown) ->
          Openreader.entries_loaded(Openreader.current_feed_id)
          if xhr.status == 404
            Openreader.alertTimedShowHide $("#no-entries")
          else
            Openreader.alertTimedShowHide $("#problem-loading")


  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Function to insert new entries in the list
  #-------------------------------------------------------
  insert_entries = (entries, status, xhr) ->
    $("#feed-entries").html entries
    Openreader.entries_loaded(Openreader.current_feed_id)

  #-------------------------------------------------------
  # Show the feed title and link it to the feed URL
  #-------------------------------------------------------
  show_feed_title = (feed)->
    feed_title = $(feed).attr "data-feed-title"
    $("#feed-title a").text feed_title
    $("#feed-title").removeClass "hidden"
    feed_url = $(feed).attr "data-feed-url"
    $("#feed-title a").attr "href", feed_url

  #-------------------------------------------------------
  # Mark with a tick the current feed's folder in the dropdown
  #-------------------------------------------------------
  mark_folder_in_dropdown = ->
    $("#folder-management-dropdown a[data-folder-id] i.icon-ok").addClass "hidden"
    $("#folder-management-dropdown a[data-folder-id='#{Openreader.current_feed_folder_id}'] i.icon-ok")
      .removeClass "hidden"

  #-------------------------------------------------------
  # Set global variables with the currently selected feed, its folder, path and refresh path.
  #-------------------------------------------------------
  set_global_variables = (feed)->
    Openreader.current_feed_path = $(feed).attr "data-feed-path"
    Openreader.current_feed_refresh_path = $(feed).attr "data-refresh-path"
    Openreader.current_feed_id = $(feed).attr "data-feed-id"
    Openreader.current_feed_folder_id = $(feed).attr "data-folder-id"
    Openreader.current_feed_folder_id ||= "none"
    Openreader.current_folder_id = $(feed).parent().closest("[data-folder-id]").attr "data-folder-id"