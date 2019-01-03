require 'spec_helper'

describe 'SocialWallet::Client on DB' do
  let(:account_id) { 'pietro' }
  let(:another_account_id) { 'paolo' }
  let(:to_id) { 'aaron' }
  let(:amount) { 10.0 }
  let(:tags) { %w[tag_1 tag_2] }
  let(:description) { "Test description #{Time.now}" }
  let(:blockchain) { 'mongo' }
  subject(:client) {
    SocialWallet::Client.new(
      api_endpoint: ENV['TEST_API_ENDPOINT'],
      api_key:      ENV['TEST_API_KEY']
    )
  }

  context '#balance' do
    before do
      @balance = client.balance(account_id: account_id)
    end
    it 'retrieve the balance of a given account' do
      expect(@balance['amount'].to_s).to match(/-?\d+(\.\d+)?/)
    end
  end

  context '#label' do
    it 'retrieve the label of the blockchain' do
      resp = client.label
      expect(resp['currency']).to be_a(String)
    end
  end

  context '#tags' do
    before do
      client.transactions.new(
        from_id: account_id, to_id: to_id, amount: amount, tags: tags
      )
      @list = client.tags.list
    end
    context '#list' do
      it 'retrieve the list of tags and contains the correct data' do
        expect(@list['tags']).to be_a(Array)
        element = @list['tags'].select { |element| element['tag'] == tags.first }.first
        expect(element['tag']).to eq(tags.first)
        expect(element['count']).to be >= 1
        expect(element['amount']).to be >= amount
        expect(element['created-by']).to eq(account_id)
      end
    end
  end

  context '#transactions' do
    context '#list' do
      before do
        resp = client.transactions.new(
          from_id: account_id, to_id: to_id, amount: amount, tags: tags,
          description: description
        )
        @transaction_id = resp['transaction-id']
        @timestamp = resp['timestamp']
        sleep 1 # needed to be sure that time passes...
        @list = client.transactions(account_id: account_id).list(
          from_datetime: Time.now - 3600,
          to_datetime:   Time.now, # not using it means up to now
          # description:   description, # not really implemented yet
          tags:          tags
        )
        @currency = client.label['currency']
      end
      it 'retrieve the list of transactions and contains the correct data' do
        expect(@list).to be_a(Hash)
        expect(@list['total-count']).to be >= 1
        element = @list['transactions'].select { |element| element['transaction-id'] == @transaction_id }.first
        expect(element['from-id']).to eq(account_id)
        expect(element['to-id']).to eq(to_id)
        expect(element['amount']).to eq(amount)
        expect(element['tags']).to eq(tags)
        expect(element['timestamp']).to eq(@timestamp)
        expect(element['currency']).to eq(@currency)
      end
    end

    context '#new' do
      before do
        @currency = client.label['currency']
      end
      it 'perform a new transaction on the DB from one account to another account' do
        resp = client.transactions.new(
          from_id: account_id, to_id: to_id, amount: amount, tags: tags,
          description: description
        )
        expect(resp['from-id']).to eq(account_id)
        expect(resp['to-id']).to eq(to_id)
        expect(resp['amount']).to eq(amount)
        expect(resp['description']).to eq(description)
        expect(resp['tags']).to eq(tags)
        expect(resp['transaction-id']).not_to be_nil
        expect { Time.parse(resp['timestamp']) }.to_not raise_error
        expect(resp['currency']).to eq(@currency)
      end
    end

    context '#get' do
      before do
        resp = client.transactions.new(
          from_id: account_id, to_id: to_id, amount: amount, tags: tags,
          description: description
        )
        @transaction_id = resp['transaction-id']
        @timestamp = resp['timestamp']
        @currency = client.label['currency']
      end
      it 'retrieve info on a transaction' do
        resp = client.transactions.get(transaction_id: @transaction_id)
        expect(resp).to include(
          'from-id'        => account_id,
          'to-id'          => to_id,
          'amount'         => amount,
          'amount-text'    => BigDecimal.new(amount, 16).to_s('F'),
          # 'amount-text'    => amount.to_s,
          'description'    => description,
          'tags'           => tags,
          'transaction-id' => @transaction_id,
          'timestamp'      => @timestamp,
          'currency'       => @currency
        )
      end
    end
  end
end
