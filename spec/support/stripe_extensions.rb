require 'stripe'

module Stripe
  class BankAccount < APIResource
    include Stripe::APIOperations::Update
    include Stripe::APIOperations::Delete
    include Stripe::APIOperations::List

    def url
      if respond_to?(:customer)
        "#{Customer.url}/#{CGI.escape(customer)}/sources/#{CGI.escape(id)}"
      elsif respond_to?(:account)
        "#{Account.url}/#{CGI.escape(account)}/external_accounts/#{CGI.escape(id)}"
      end
    end

    def verify(params = {}, opts = {})
      response, opts = request(:post, verify_url, params, opts)
      refresh_from(response, opts)
    end

    def self.retrieve(id, opts=nil)
      raise NotImplementedError.new("Bank accounts cannot be retrieved without an account ID. Retrieve a bank account using account.external_accounts.retrieve('card_id')")
    end

    private
    def bank_account_url
      if respond_to?(:customer)
        "#{Customer.url}/#{CGI.escape(customer)}/bank_accounts/#{CGI.escape(id)}"
      elsif respond_to?(:account)
        "#{Account.url}/#{CGI.escape(account)}/bank_accounts/#{CGI.escape(id)}"
      end
    end

    def verify_url
      bank_account_url + '/verify'
    end
  end

  Util.object_classes['bank_account'] = BankAccount

end
