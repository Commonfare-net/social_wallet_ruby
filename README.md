# SocialWallet

A simple ruby client for the [Social Wallet API](https://github.com/Commonfare-net/social-wallet-api). It supports both the backends of the SWAPI: the *database* (e.g. `mongo`), for local transactions within the wallet, and the *blockchain* (e.g. `faircoin`), for transactions between the wallet addresses and public addresses on a blockchain.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'social_wallet'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install social_wallet

## Usage

### ⚠️ Version compatibility ⚠️

If you use [Social Wallet API](https://github.com/Commonfare-net/social-wallet-api) version ≤ 0.10.x you must use [v1.0.3 of this gem](https://github.com/Commonfare-net/social_wallet_ruby/tree/5fe6ee36f3055de165540f49eb03e54ea9fc268d).

### Create the client

The default client uses the *database* `mongo` as backend.

```ruby
client = SocialWallet::Client.new(api_endpoint: 'http://example.com/wallet/v1')
```

This constructor defaults to a client that uses `connection: 'mongo'` and `type: 'db-only'`.
If you want to use the API on a different backend just specify it like this:

```ruby
client = SocialWallet::Client.new(api_endpoint: 'http://example.com/wallet/v1', connection: 'faircoin', type: 'blockchain-and-db')
```

### List of tags

Retrieve the list of tags of the *database* backend.

```ruby
client.tags.list
#=> { "tags" => [{ "tag"=>"something", "count"=>1, "amount"=>0.1, "created-by"=>"test-1", "created"=>"2018-02-01T10:58:10.728" }, ...]
```

### Transactions

Always use `account_id` when managing transactions.

#### New

This call is *database-only*, for transactions on the blockchain please refer to [Withdraws](#withdraws) and [Deposits](#deposits).

Move some amount from one account (`paolo`) to another account (`aaron`)

```ruby
client.transactions.new(from_id: 'paolo', to_id: 'aaron', amount: 10, tags: ['tag1', 'tag2'])
```

#### List

Retrieve the list of the transactions of a specific account.

```ruby
client.transactions(account_id: 'pietro', count: 0, from: 0, page: 0, per_page: 0, currency: 'Commoncoin').list(from_datetime: Time.now - 3600, to_datetime: Time.now)
```

To retrieve the list of the transactions of the default account use `account_id: ''`

##### Optional parameters

* **Paginated results**: for *database* transactions use `:page` and `:per_page` (defaults: `page: 1`, `per_page: 10`. Use `0` for ALL), for *blockchain* transactions use `:count` and `:from`.

* **Filter by currency**: another optional parameter for *database* transactions is `:currency`, to filter transactions only by one currency.

* **Filter by dates**: use `from_datetime` and `to_datetime`.

**Response**

The list of transactions is always paginated to avoid overload on the server.

```ruby
{
  'total-count'=>42,
  'transactions'=>[
    {
      'tags'=>['tag1', 'tag2'],
      'timestamp'=>'2018-02-23T20:10:01.331',
      'from-id'=>'pietro',
      'to-id'=>'aaron',
      'amount'=>10,
      'amount-text'=>'10.0',
      'transaction-id'=>'xqc4cvhr...pCPfju5inCO',
      'currency'=>'Commoncoin'
      'description'=>'...'
    },
    {
      ...
    }]
}
```

**IMPORTANT**: the format of the response varies according to the backend used (e.g. `faircoin` or `mongo`). See the [Get](#transactions-get) for details.

<span id="#transactions-get"></span>

#### Get

Retrieve info about a specific transaction.

```ruby
client.transactions.get(transaction_id: 'transaction_id')
```

**Response**

The schema of the response varies according to the backend used (e.g. `faircoin` or `mongo`).

On *database*:

```ruby
client.transactions.get transaction_id: 'xqc4cvhr...pCPfju5inCO'
#=>
{
  'tags'=>['tag1', 'tag2'],
  'timestamp'=>'2018-02-23T20:10:01.331',
  'from-id'=>'pietro',
  'to-id'=>'aaron',
  'amount'=>10,
  'amount-text'=>'10.0',
  'transaction-id'=>'xqc4cvhr...pCPfju5inCO',
  'currency'=>'Commoncoin'
}
```

On *blockchain*

```ruby
client.transactions.get transaction_id: 'f747a7870ce82385802705...bf2cc219cfe08'
#=>
{
  'confirmations'=>10452,
  'hex'=>
  '010000000...a88acc6790100',
  'walletconflicts'=>[],
  'blockhash'=>'132f223a466...dfa5c0c1d02c876ab4e1',
  'time'=>1517832065,
  'amount'=>0.1,
  'details'=>[
    {'account'=>'',
      'address'=>'fEGhnSZWB...84yCsvEbS4',
      'category'=>'receive',
      'amount'=>0.1,
      'label'=>'',
      'vout'=>0}
    ],
  'bip125-replaceable'=>'no',
  'blocktime'=>1517832033,
  'timereceived'=>1517832065,
  'blockindex'=>1,
  'txid'=>'f747a7870ce82385802705...c7d93969f4edbf2cc219cfe08'
}
```

### Balance

Balance of a specific account:

```ruby
client.balance(account_id: 'pietro')
#=> { 'amount' => 42 }
```

Balance of the default account:

```ruby
client.balance(account_id: '')
#=> { 'amount' => -84.24 }
```

Total balance of the wallet:

```ruby
client.balance
#=> { 'amount' => -42.24 }
```

### Label

Retrieve the label of the currency for the client's backend

```ruby
client.label
#=> { 'currency' => 'Commoncoin' }
```

### Address

Retrieve a list of addresses for a specific account.

```ruby
client.address(account_id: account_id)
```

Retrieve a list of addresses for the default account.

```ruby
client.address
```

<span id="withdraws"></span>

### Withdraws

This call withdraws an amount from the default account `''` or optionally a given `from_wallet_account` to a provided *blockchain* address (`to_address`). Also a transaction on the *database* will be registered. If fees apply for this transaction those fees will be added to the amount on the *database* when the transaction reaches the required amount of confirmations (configured in the wallet).

`Withdraws` are *blockchain-only*.

```ruby
client.withdraws.new(
  from_id: '',
  from_wallet_account: '',
  to_address: '',
  amount: 10,
  tags: ['tag1', 'tag2'],
  comment: '',
  comment_to: ''
)
```

**Some details**

* `from_wallet_account` is the (optional) *blockchain* address among those that exist inside the wallet. When set to `''`, the default address of the wallet is used.
* `from_id` is the (optional) `account_id` inside the wallet from which the transaction originates. Once the withdraw is confirmed, the transaction registered on the database has  this `from_id`.

<span id="deposits"></span>

### Deposits

`Deposits` are *blockchain-only*.

#### New

Returns an address onto which the coins should be received. The `to_id` is the (optional) `account_id` within the wallet which receives the coins.

```ruby
client.deposits.new(to_id: '', to_wallet_id: '', tags: ['tag1', 'tag2'])
```

When `to_wallet_id` is used it will create the address for a particular account in the wallet and the default otherwise. If the account is not found, the address will be created on the default account.

#### Check

Check the status of the deposit to the specified `address`.

```ruby
client.deposits.check(address: 'address')
```

### Summary

This table summarizes which are the available methods for the different backends.

| method                   | database | blockchain |
|--------------------------|:--------:|:----------:|
| `tags.list`              | ✅        | 🚫         |
| `transactions(...).new`  | ✅        | 🚫         |
| `transactions(...).list` | ✅        | ✅         |
| `transactions(...).get`  | ✅        | ✅         |
| `balance`                | ✅        | ✅         |
| `label`                  | ✅        | ✅         |
| `address`                | 🚫        | ✅         |
| `withdraws.new`          | 🚫        | ✅         |
| `deposits.new`           | 🚫        | ✅         |
| `deposits.check`         | 🚫        | ✅         |

Using a method on the wrong backend will raise a `SocialWallet::Error`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

Before running tests, copy the file `test_env.yml.example` to `test_env.yml` and fill that file with the appropriate values.

<!-- To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org). -->


## Acknowledgements

The Social Wallet gem is Free and Open Source research and development activity funded by the European Commission in the context of the [Collective Awareness Platforms for Sustainability and Social Innovation (CAPSSI)](https://ec.europa.eu/digital-single-market/en/collective-awareness) program. Social Wallet gem uses the [Social Wallet API](https://github.com/Commonfare-net/social-wallet-api) and it has been adopted as a component of the [Commonfare platform](https://commonfare.net) being developed for
the [Commonfare - PIE News project](https://pieproject.eu) (grant nr. 687922).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Commonfare-net/social_wallet_ruby.
