##
# Class with methods related to managing resque schedules.

class ScheduleManager

  ##
  # For each feed in the database, ensure that resque-schedule has a scheduled update for the feed.
  #
  # If a feed is found with no scheduled update, a job is scheduled to update the feed periodically.
  #
  # After invoking this method all feeds have scheduled updates that run every hour.
  #
  # Note.- This methods relies on the schedule to run updates for a feed being named "update_feed_#{feed.id}". If this
  # naming scheme ever changes, this method will have to be changed accordingly.

  def self.fix_update_schedules
    Rails.logger.debug 'Fixing feed update schedules'
    feeds_unscheduled = []

    Feed.where(available: true).each do |feed|
      # get update schedule for the feed
      schedule = Resque.fetch_schedule "update_feed_#{feed.id}"
      Rails.logger.debug "Update schedule for feed #{feed.id}  #{feed.title}: #{schedule}"

      # if a feed has no update schedule, add it to the array of feeds to be fixed
      if schedule.nil?
        Rails.logger.warn "Missing schedule for feed #{feed.id} - #{feed.title}"
        feeds_unscheduled << feed
      end
    end

    if feeds_unscheduled.length > 0
      Rails.logger.warn "A total of #{feeds_unscheduled.length} feeds are missing their update schedules. Adding missing schedules."
      feeds_unscheduled.each do |feed|
        add_missing_schedule feed
      end
    end
  end

  ##
  # Schedule updating of a feed using Resque-scheduler.
  # Receives as argument the id of the feed which update is to be scheduled.
  #
  # There can only be one scheduled job for updates of a given feed. If there is a scheduled update
  # job for a feed and this method is invoked with the id of that feed, the old schedule is updated.
  #
  # Scheduled jobs are named "update_feed_[feed_id]", they can be monitored using the Resque web console.
  #
  # The first run of a job is scheduled to happen a random amount of minutes, between 0 and 60, after this
  # method is invoked. After that the job is run every hour. This is done so that feed updates are more or less
  # evenly, or at least randomly, spaced in time. This way the server load from the updates is spaced over
  # time, to affect user experience as little as possible.

  def self.schedule_feed_updates(feed_id)
    delay = Random.rand 61
    Rails.logger.info "Scheduling updates of feed #{feed_id} every hour, starting #{delay} minutes from now at #{Time.now + delay.minutes}"
    set_or_update_schedule feed_id, 1.hour, delay.minutes
  end

  ##
  # Unschedule (this is, remove from scheduling) the update feed job for the passed feed.
  # Receives as argument the id of the feed which update is to be unscheduled.
  #
  # After invoking this method, an update job for this feed will never be enqueued again (at least while
  # schedule_feed_updates is not invoked again for this feed).

  def self.unschedule_feed_updates(feed_id)
    Rails.logger.info "Unscheduling updates of feed #{feed_id}"
    Resque.remove_schedule "update_feed_#{feed_id}"
  end

  ##
  # Decrement the interval between updates of the passed feed.
  # The current interval is decremented by 10% up to the minimum set in
  # the application configuration.

  def self.decrement_update_interval(feed)
    new_interval = (feed.fetch_interval_secs * 0.9).round
    min = Feedbunch::Application.config.min_update_interval
    new_interval = min if new_interval < min

    # Decrement the update interval saved in the database
    Rails.logger.debug "Decrementing update interval of feed #{feed.id} - #{feed.title} to #{new_interval} seconds"
    feed.update fetch_interval_secs: new_interval

    # Actually decrement the update interval in Resque
    set_or_update_schedule feed.id, feed.fetch_interval_secs, feed.fetch_interval_secs
  end

  ##
  # Increment the interval between updates of the passed feed.
  # The current interval is incremented by 10% up to the maximum set in
  # the application configuration.

  def self.increment_update_interval(feed)
    new_interval = (feed.fetch_interval_secs * 1.1).round
    max = Feedbunch::Application.config.max_update_interval
    new_interval = max if new_interval > max

    # Increment the update interval saved in the database
    Rails.logger.debug "Incrementing update interval of feed #{feed.id} - #{feed.title} to #{new_interval} seconds"
    feed.update fetch_interval_secs: new_interval

    # Actually increment the update interval in Resque
    set_or_update_schedule feed.id, feed.fetch_interval_secs, feed.fetch_interval_secs
  end

  private

  ##
  # Set scheduled updates for a feed or, if the schedule already exists, update its
  # configuration.
  # Receives as arguments:
  # - ID of the feed for which updates are scheduled
  # - every_seconds: interval, in seconds, between updates
  # - first_in_seconds (optional): how many seconds from now will the first update run.

  def self.set_or_update_schedule(feed_id, every_seconds, first_in_seconds = nil)
    name = "update_feed_#{feed_id}"
    config = {}
    config[:persist] = true
    config[:class] = 'ScheduledUpdateFeedJob'
    config[:args] = feed_id

    interval = "#{every_seconds}s"
    if first_in_seconds.present?
      every = [interval, {first_in: first_in_seconds}]
    else
      every = interval
    end
    config[:every] = every

    Rails.logger.debug "Setting new resque schedule for updates of feed #{feed_id} every #{every_seconds} seconds, beginning in #{first_in_seconds} seconds"
    Resque.set_schedule name, config
  end

  ##
  # Add a missing update schedule for a feed. Receives the feed as argument.
  # The next update will be scheduled to run at fetch_interval_secs seconds after last_fetched, as if the schedule
  # had not disappeared, unless that time has already passed, in which case it will be scheduled immediately.

  def self.add_missing_schedule(feed)
    Rails.logger.warn "Adding missing update schedule for feed #{feed.id} - #{feed.title}"

    if feed.last_fetched.blank?
      # If feed has never been fetched, schedule its first update sometime in the next hour
      delay = Random.rand 61
      first_in = delay.minutes
    else
      # Calculate how much time is left until the moment when the next update should have been scheduled
      first_in = (feed.last_fetched + feed.fetch_interval_secs.seconds - Time.zone.now).seconds.round

      # If the moment the next update should have been scheduled is in the past, schedule an update
      # sometime in the next 15 minutes.
      if first_in < 0
        delay = Random.rand 901
        first_in = delay.seconds
      end
    end

    set_or_update_schedule feed.id, feed.fetch_interval_secs, first_in
  end
end