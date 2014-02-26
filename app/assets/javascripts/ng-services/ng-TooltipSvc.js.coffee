########################################################
# AngularJS service to enable tooltips on elements
########################################################

angular.module('feedbunch').service 'tooltipSvc',
['$rootScope', ($rootScope)->

  # Media query to enable tooltips only in screens wider than a tablet's
  md_min_media_query = 'screen and (min-width: 992px)'

  #---------------------------------------------
  # Enable tooltips on some entry buttons and links
  #---------------------------------------------
  entry_tooltips: (entry)->
    # Do not enable tooltips in smartphone and tablet-sized screens
    enquire.register md_min_media_query, ->
      $("#entry-#{entry.id} a[data-toggle='tooltip']").tooltip()

  #---------------------------------------------
  # Enable tooltips on navbar buttons
  #---------------------------------------------
  navbar_tooltips: ->
    # Do not enable tooltips in smartphone and tablet-sized screens
    enquire.register md_min_media_query, ->
      $(".navbar .nav.navbar-nav li[data-toggle='tooltip']").tooltip()

  #---------------------------------------------
  # Enable tooltips on the feed title link
  #---------------------------------------------
  feed_title_tooltip: ->
    # Do not enable tooltips in smartphone and tablet-sized screens
    enquire.register md_min_media_query, ->
      $("#feed-title a[data-toggle='tooltip']").tooltip()
]