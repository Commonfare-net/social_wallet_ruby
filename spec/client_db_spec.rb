require 'spec_helper'

describe 'SocialWallet::Client on DB' do
  let(:account_id) { 'pietro' }
  let(:another_account_id) { 'paolo' }
  let(:to_id) { 'aaron' }
  let(:amount) { 10.0 }
  let(:tags) { %w[tag_1 tag_2] }
  let(:blockchain) { 'mongo' }
  subject(:client) {
    SocialWallet::Client.new(
      api_endpoint: ENV['TEST_API_ENDPOINT']
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
      expect(resp['currency']).to eq(blockchain.upcase)
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
      it 'retrieve the list of tags' do
        expect(@list['tags']).to be_a(Array)
      end
      it 'contains the correct data' do
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
          from_id: account_id, to_id: to_id, amount: amount, tags: tags
        )
        @transaction_id = resp['transaction-id']
        @list = client.transactions(account_id: account_id).list
      end
      it 'retrieve the list of transactions' do
        expect(@list).to be_a(Array)
      end
      it 'contains the correct data' do
        element = @list.select { |element| element['transaction-id'] == @transaction_id }.first
        expect(element['from-id']).to eq(account_id)
        expect(element['to-id']).to eq(to_id)
        expect(element['amount']).to eq(amount)
        expect(element['tags']).to eq(tags)
      end
    end

    # context '#move' do
    #   it "move some amount from the requester's account to another account" do
    #     resp = client.transactions(account_id).move(
    #       to_id: to_id, amount: amount, tags: tags
    #     )
    #     expect(resp['from-id']).to eq(account_id)
    #     expect(resp['to-id']).to eq(to_id)
    #     expect(resp['amount']).to eq(amount)
    #     expect(resp['tags']).to eq(tags)
    #     expect(resp['transaction-id']).not_to be_nil
    #   end
    #
    #   it 'move some amount from one account to another account' do
    #     resp = client.transactions(account_id).move(
    #       from_id: another_account_id, to_id: to_id, amount: amount, tags: tags
    #     )
    #     expect(resp['from-id']).to eq(another_account_id)
    #     expect(resp['to-id']).to eq(to_id)
    #     expect(resp['amount']).to eq(amount)
    #     expect(resp['tags']).to eq(tags)
    #     expect(resp['transaction-id']).not_to be_nil
    #   end
    # end

    context '#new' do
      it 'perform a new transaction on the DB from one account to another account' do
        resp = client.transactions.new(
          from_id: account_id, to_id: to_id, amount: amount, tags: tags
        )
        expect(resp['from-id']).to eq(account_id)
        expect(resp['to-id']).to eq(to_id)
        expect(resp['amount']).to eq(amount)
        expect(resp['tags']).to eq(tags)
        expect(resp['transaction-id']).not_to be_nil
      end
    end

    context '#get' do
      before do
        resp = client.transactions.new(
          from_id: account_id, to_id: to_id, amount: amount, tags: tags
        )
        @transaction_id = resp['transaction-id']
        @label = client.label['currency']
      end
      it 'retrieve info on a transaction' do
        resp = client.transactions.get(transaction_id: @transaction_id)
        expect(resp).to include(
          'from-id'        => account_id,
          'to-id'          => to_id,
          'amount'         => amount,
          'amount-text'    => BigDecimal.new(amount, 16).to_s('F'),
          # 'amount-text'    => amount.to_s,
          'tags'           => tags,
          'transaction-id' => @transaction_id,
          'currency'       => @label
        )
      end
    end
  end
end
