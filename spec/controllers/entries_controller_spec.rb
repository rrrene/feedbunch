require 'spec_helper'

describe EntriesController do

  before :each do
    # Ensure no actual HTTP calls are done
    RestClient.stub :get

    @feed = FactoryGirl.create :feed
    @user = FactoryGirl.create :user
    @user.feeds << @feed
    @entry = FactoryGirl.build :entry, feed_id: @feed.id
    @feed.entries << @entry
    login_user_for_unit @user
  end

  context 'PUT update' do
    it 'returns success' do
      put :update, id: @entry.id, state: 'read'
      response.should be_success
    end

    it 'returns 404 if the folder does not exist' do
      put :update, id: 1234567890, state: 'read'
      response.status.should eq 404
    end

    it 'returns 404 if the user is not subscribed to the entries feed' do
      entry2 = FactoryGirl.create :entry
      put :update, id: entry2.id, state: 'read'
      response.status.should eq 404
    end

    it 'returns 500 if there is a problem changing the entry state' do
      User.any_instance.stub(:change_entry_state).and_raise StandardError.new
      put :update, id: @entry.id, state: 'read'
      response.status.should eq 500
    end

    it 'assigns the correct feed to @feed' do
      put :update, id: @entry.id, state: 'read'
      assigns(:feed).should eq @feed
    end
  end
end