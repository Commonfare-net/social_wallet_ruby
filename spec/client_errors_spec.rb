require 'spec_helper'

describe 'SocialWallet::Client Errors' do
  let(:account_id) { 'pietro' }
  let(:another_account_id) { 'paolo' }
  let(:to_id) { 'aaron' }
  let(:amount) { 10 }
  let(:tags) { %w[tag1 tag2] }
  let(:blockchain) { 'mongo' }
  subject(:client) {
    SocialWallet::Client.new(
      api_endpoint: ENV['TEST_API_ENDPOINT']
    )
  }
  subject(:bad_client) {
    SocialWallet::Client.new(
      api_endpoint: ENV['TEST_API_ENDPOINT'],
      blockchain:   'bad_name'
    )
  }

  context '#label returns an error message when' do
    it 'retrieve the label of a non-existing blockchain' do
      expect { bad_client.label }.to raise_error(SocialWallet::Error)
    end
  end
end
