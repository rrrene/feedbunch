require 'spec_helper'

describe 'feeds' do
  before :each do
    # Ensure no actual HTTP calls are made
    FeedClient.stub :fetch
    RestClient.stub :get
  end

  it 'redirects unauthenticated visitors to login page' do
    visit feeds_path
    current_path.should eq new_user_session_path
  end

  context 'subscription to feeds' do

    before :each do
      @user = FactoryGirl.create :user
      @feed1 = FactoryGirl.create :feed
      @feed2 = FactoryGirl.create :feed
      @user.feeds << @feed1

      login_user_for_feature @user
      visit feeds_path
    end

    it 'shows feeds the user is subscribed to' do
      page.should have_content @feed1.title
    end

    it 'does not show feeds the user is not subscribed to' do
      page.should_not have_content @feed2.title
    end

    it 'subscribes to a feed'

    it 'unsubscribes from a feed'
  end

  context 'folders' do

    before :each do
      @user = FactoryGirl.create :user

      @folder1 = FactoryGirl.build :folder, user_id: @user.id
      @folder2 = FactoryGirl.create :folder
      @user.folders << @folder1

      @feed1 = FactoryGirl.build :feed
      @feed2 = FactoryGirl.build :feed
      @user.feeds << @feed1 << @feed2
      @folder1.feeds << @feed1

      @entry1_1 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry1_2 = FactoryGirl.build :entry, feed_id: @feed1.id
      @entry2_1 = FactoryGirl.build :entry, feed_id: @feed2.id
      @entry2_2 = FactoryGirl.build :entry, feed_id: @feed2.id
      @feed1.entries << @entry1_1 << @entry1_2
      @feed2.entries << @entry2_1 << @entry2_2

      login_user_for_feature @user
      visit feeds_path
    end

    it 'shows only folders that belong to the user' do
      page.should have_content @folder1.title
      page.should_not have_content @folder2.title
    end

    it 'shows an All Subscriptions folder with all feeds subscribed to', js: true do
      within 'ul#sidebar' do
        page.should have_content 'All subscriptions'

        within 'li#folder-all' do
          page.should have_css "a[data-target='#feeds-all']"

          # "All feeds" folder should be closed (class "in" not present)
          page.should_not have_css 'ul#feeds-all.in'

          # Open "All feeds" folder (should acquire class "in")
          find("a[data-target='#feeds-all']").click
          page.should have_css 'ul#feeds-all.in'

          # Should have all the feeds inside
          within 'ul#feeds-all' do
            page.should have_css "li#feed-#{@feed1.id}"
            page.should have_css "li#feed-#{@feed2.id}"
          end
        end
      end
    end

    it 'shows folders containing their respective feeds', js: true do
      within 'ul#sidebar' do
        page.should have_content @folder1.title

        within "li#folder-#{@folder1.id}" do
          page.should have_css "a[data-target='#feeds-#{@folder1.id}']"

          # Folder should be closed (class "in" not present)
          page.should_not have_css "ul#feeds-#{@folder1.id}.in"

          # Open folder (should acquire class "in")
          find("a[data-target='#feeds-#{@folder1.id}']").click
          page.should have_css "ul#feeds-#{@folder1.id}.in"

          # Should have inside only those feeds associated to the folder
          within "ul#feeds-#{@folder1.id}" do
            page.should have_css "li#feed-#{@feed1.id}"
            page.should_not have_css "li#feed-#{@feed2.id}"
          end
        end
      end
    end

    it 'shows entries for a feed in the All Subscriptions folder', js: true do
      within 'ul#sidebar li#folder-all' do
        # Open "All feeds" folder
        find("a[data-target='#feeds-all']").click

        # click on feed
        find("li#feed-#{@feed2.id} > a").click
      end

      # Only entries for the clicked feed should appear
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
      page.should_not have_content @entry1_1.title
      page.should_not have_content @entry1_2.title
    end

    it 'shows entries for a feed inside a user folder', js: true do
      within "ul#sidebar li#folder-#{@folder1.id}" do
        # Open folder @folder1
        find("a[data-target='#feeds-#{@folder1.id}']").click

        # Click on feed
        find("li#feed-#{@feed1.id} > a").click
      end

      # Only entries for the clicked feed should appear
      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should_not have_content @entry2_1.title
      page.should_not have_content @entry2_2.title
    end

    it 'shows a link to read entries for all subscriptions inside the All Subscriptions folder', js: true do
      within 'ul#sidebar li#folder-all' do
        # Open "All feeds" folder
        find("a[data-target='#feeds-all']").click

        page.should have_css 'li#folder-all-all-feeds'

        # Click on link to read all feeds
        find('li#folder-all-all-feeds > a').click
      end

      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should have_content @entry2_1.title
      page.should have_content @entry2_2.title
    end

    it 'shows a link to read all entries for all subscriptions inside a folder', js: true do
      # Add a second feed inside @folder1
      feed3 = FactoryGirl.create :feed
      @user.feeds << feed3
      @folder1.feeds << feed3
      entry3_1 = FactoryGirl.build :entry, feed_id: feed3.id
      entry3_2 = FactoryGirl.build :entry, feed_id: feed3.id
      feed3.entries << entry3_1 << entry3_2

      within "ul#sidebar li#folder-#{@folder1.id}" do
        # Open folder
        find("a[data-target='#feeds-#{@folder1.id}']").click

        page.should have_css "li#folder-#{@folder1.id}-all-feeds"

        # Click on link to read all feeds
        find("li#folder-#{@folder1.id}-all-feeds > a").click
      end

      page.should have_content @entry1_1.title
      page.should have_content @entry1_2.title
      page.should have_content entry3_1.title
      page.should have_content entry3_2.title
      page.should_not have_content @entry2_1.title
      page.should_not have_content @entry2_2.title
    end

    it 'shows a notice if the feed clicked has no entries'

    it 'adds a feed to a new folder'

    it 'adds a feed to an existing folder'

    it 'removes a feed from a folder'

    it 'totally removes a folder when it has no feeds under it'
  end

  context 'refresh' do

    it 'refreshes a single feed'

    it 'refreshes all subscribed feeds'

    it 'refreshes all subscribed feeds inside a folder'
  end

  context 'entries' do

    it 'opens an entry'

    it 'closes other entries when opening an entry'

    it 'marks as read an entry when opening it'

    it 'marks all entries as read'

    it 'marks an entry as unread'

  end
end