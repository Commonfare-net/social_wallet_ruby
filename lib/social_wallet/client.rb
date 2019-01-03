module SocialWallet
  class Client
    attr_accessor :api_endpoint, :blockchain, :request_data, :connection, :type

    SW_ERROR_STATUSES = [404, 503].freeze

    def initialize(
      api_endpoint: nil,
      blockchain: 'mongo',
      connection: 'mongo',
      type: 'db-only'
    )
      @api_endpoint = api_endpoint
      @blockchain = blockchain # NOTE: here for backward compatibility
      @connection = connection
      @type = type
      @request_data = { connection: connection, type: type }
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

    def ___transactions(
      account_id: nil,
      count:      nil,
      from:       nil,
      page:       nil,
      per_page:   nil,
      currency:   nil
    )
      @account_id = account_id
      @count = count
      @from = from
      @page = page
      @per_page = per_page
      @currency = currency
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
      conn = Faraday.new(connection_params)
      response = conn.post do |req|
        req.headers.merge!(headers)
        request_data['account-id'] = account_id if account_id
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___label
      conn = Faraday.new(connection_params)
      response = conn.post do |req|
        req.headers.merge!(headers)
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___address(account_id: '')
      conn = Faraday.new(connection_params)
      response = conn.post do |req|
        req.headers.merge!(headers)
        request_data['account-id'] = account_id
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___new(
      from_id:             nil,
      to_id:               nil,
      amount:              0,
      from_wallet_account: '',
      to_wallet_id:        '',
      to_address:          '',
      comment:             '',
      comment_to:          '',
      description:         '',
      tags:                []
    )
      conn = Faraday.new(connection_params)
      response = conn.post do |req|
        req.headers.merge!(headers)
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
          request_data['description'] = description
        end
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___list(
      from_datetime: nil,
      to_datetime:   nil,
      description:   nil,
      tags:          nil
    )
      conn = Faraday.new(connection_params)
      response = conn.post do |req|
        req.headers.merge!(headers)
        if @path_parts.include?('transactions')
          request_data['account-id'] = @account_id
          request_data['count'] = @count unless @count.nil?
          request_data['from'] = @from unless @from.nil?
          request_data['page'] = @page unless @page.nil?
          request_data['per-page'] = @per_page unless @per_page.nil?
          request_data['currency'] = @currency unless @currency.nil?
          request_data['from-datetime'] = from_datetime.iso8601 if from_datetime.is_a? Time
          request_data['to-datetime'] = to_datetime.iso8601 if to_datetime.is_a? Time
          request_data['description'] = description unless description.nil?
          request_data['tags'] = tags unless tags.nil?
        end
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___get(transaction_id: nil)
      conn = Faraday.new(connection_params)
      response = conn.post do |req|
        req.headers.merge!(headers)
        request_data[:txid] = transaction_id
        req.body = MultiJson.dump(request_data)
      end
      format_response(response)
    ensure
      reset
    end

    def ___check(address: '')
      conn = Faraday.new(connection_params)
      response = conn.post do |req|
        req.headers.merge!(headers)
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
      @request_data = { connection: connection, type: type }
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

    def connection_params
      {
        url: api_endpoint + '/' + path,
        ssl: { version: 'TLSv1_2' }
      }
    end

    def headers
      {
        'Content-Type' => 'application/json',
        # 'x-api-key'    => ENV['SOCIAL_WALLET_API_KEY']
      }
    end
  end
end
