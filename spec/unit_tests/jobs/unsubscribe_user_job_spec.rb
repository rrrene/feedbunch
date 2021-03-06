require 'rails_helper'

describe UnsubscribeUserJob do

  before :each do
    @user = FactoryGirl.create :user
    @feed = FactoryGirl.create :feed
    @user.subscribe @feed.fetch_url
  end

  it 'unsubscribes user from feed' do
    expect(@user.feeds).to include @feed
    UnsubscribeUserJob.perform @user.id, @feed.id
    @user.reload
    expect(@user.feeds).not_to include @feed
  end

  context 'validations' do

    it 'does nothing if the user does not exist' do
      expect_any_instance_of(User).not_to receive :unsubscribe
      UnsubscribeUserJob.perform 1234567890, @feed.id
    end

    it 'does nothing if the feed does not exist' do
      expect(@user).not_to receive :unsubscribe
      UnsubscribeUserJob.perform @user.id, 1234567890
    end

    it 'does nothing if the feed is not subscribed by the user' do
      folder = FactoryGirl.create :folder
      expect(@user).not_to receive :subscribe
      SubscribeUserJob.perform @user.id, @feed.fetch_url, folder.id, false, nil
    end

  end
end