require 'spec_helper'

describe 'SocialWallet::Client on Blockchain' do
  let(:account_id) { '' }
  let(:another_account_id) { '' }
  let(:to_id) { '' }
  let(:amount) { 0.01 }
  let(:tags) { %w[tag1 tag2] }
  let(:blockchain) { 'faircoin' }
  subject(:client) {
    SocialWallet::Client.new(
      api_endpoint: ENV['TEST_API_ENDPOINT'],
      blockchain:   blockchain
    )
  }

  context '#balance' do
    before do
      @balance_of_account = client.balance(account_id: account_id)
      @balance_of_default_account = client.balance(account_id: '')
      @balance_of_wallet = client.balance
    end
    it 'retrieve the balance of a given account' do
      # TODO: test with account_id
      expect(@balance_of_account['amount'].to_s).to match(/-?\d+(\.\d+)?/)
    end
    it 'retrieve the balance of the default account' do
      # TODO: test with account_id
      expect(@balance_of_default_account['amount'].to_s).to match(/-?\d+(\.\d+)?/)
    end
    it 'retrieve the balance of the wallet' do
      expect(@balance_of_wallet['amount'].to_s).to match(/-?\d+(\.\d+)?/)
    end
  end

  context '#address' do
    before do
      @addresses_of_account = client.address(account_id: account_id)
      @addresses_of_wallet = client.address
    end
    it 'retrieve the addresses of a given account' do
      # TODO: test with account_id
      expect(@addresses_of_account['addresses']).to be_a(Array)
    end
    it 'retrieve the addresses of the wallet' do
      expect(@addresses_of_wallet['addresses']).to be_a(Array)
    end
  end

  context '#withdraws' do
    pending
  end

  context '#deposits' do
    pending
  end
end
