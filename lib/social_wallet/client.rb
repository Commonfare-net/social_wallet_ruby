module SocialWallet
  class Client
    attr_accessor :api_endpoint, :blockchain, :request_data

    SW_ERROR_STATUSES = [404, 503].freeze

    def initialize(api_endpoint: nil, blockchain: 'mongo')
      @api_endpoint = api_endpoint
      @blockchain = blockchain
      @request_data = { blockchain: blockchain }
      @path_parts = []
    end

    # def method_missing(method, *args)
    #   # To support underscores, we replace them with hyphens when calling the API
    #   @path_parts << method.to_s.gsub("_", "-").downcase
    #   @path_parts << args if args.length > 0
    #   @path_parts.flatten!
    #   self
    # end

    # def respond_to_missing?(method_name, include_private = false)
    #   true
    # end

    protected

    def ___transactions(account_id: nil)
      @account_id = account_id
      self
    end

    def ___tags
      self
    end

    def ___withdraws
      self
    end

    def ___deposits
      self
    end

    def ___balance(account_id: nil)
      conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        request_data['account-id'] = account_id if account_id
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___label
      conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___address(account_id: '')
      conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        request_data['account-id'] = account_id
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    # def move(from_id: nil, to_id: nil, amount: 0, tags: [])
    #   @path_parts << 'move'
    #   conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
    #   response = conn.post do |req|
    #     req.headers['Content-Type'] = 'application/json'
    #     request_data['from-id'] = (from_id ||= @account_id)
    #     request_data['to-id'] = to_id
    #     request_data[:amount] = amount
    #     request_data[:tags] = tags
    #     req.body = MultiJson.dump(request_data)
    #   end
    #   format_response(response)
    # ensure
    #   reset
    # end

    def ___new(
      from_id:             nil,
      to_id:               nil,
      amount:              0,
      from_wallet_account: '',
      to_wallet_id:        '',
      to_address:          '',
      comment:             '',
      comment_to:          '',
      tags:                []
    )
      conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        # From SWAPI v0.9.3 amount is a String
        request_data[:amount] = BigDecimal.new(amount, 16).to_s('F')
        request_data[:tags] = tags
        # TODO: find a better way to handle this
        if @path_parts.include? 'withdraws'
          request_data['from-id'] = from_id
          request_data['from-wallet-account'] = from_wallet_account
          request_data['to-address'] = to_address
          request_data['comment'] = comment
          request_data['commentto'] = comment_to
        elsif @path_parts.include? 'deposits'
          request_data['to-id'] = to_id
          request_data['to-wallet-id'] = to_wallet_id
        elsif @path_parts.include? 'transactions'
          request_data['from-id'] = from_id
          request_data['to-id'] = to_id
        end
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___list
      conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        request_data['account-id'] = @account_id if @path_parts.include?('transactions')
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___get(transaction_id: nil)
      conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        request_data[:txid] = transaction_id
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___check(address: '')
      conn = Faraday.new(url: api_endpoint + '/' + path, ssl: { version: 'TLSv1_2' })
      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        request_data[:address] = address
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    public

    # This creates the public methods and builds the path
    protected_instance_methods.each do |protected_method_name|
      next unless protected_method_name.to_s.start_with?('___')
      public_method_name = protected_method_name.to_s.gsub('___', '')
      define_method(public_method_name.to_sym) do |*args|
        @path_parts << public_method_name.to_s
        send protected_method_name, *args
      end
    end

    private

    def path
      @path_parts.join('/')
    end

    def reset
      @path_parts = []
      @request_data = { blockchain: blockchain }
    end

    def format_response(response)
      if response.status == 200
        MultiJson.load(response.body)
      elsif SW_ERROR_STATUSES.include? response.status
        err_msg = MultiJson.load(response.body)['error']
        raise SocialWallet::Error.new(err_msg)
      else
        raise SocialWallet::Error.new("API Error: #{response.body}")
      end
    end
  end
end
