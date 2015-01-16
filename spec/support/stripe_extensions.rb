require 'stripe'
module Stripe
  class BankAccount < APIResource
    include Stripe::APIOperations::Create

    def url
      "#{Customer.url}/#{CGI.escape(customer)}/bank_accounts/#{CGI.escape(id)}"
    end

    def verify(params)
      response, api_key = Stripe.request(:post, verify_url, @api_key, params)
      refresh_from({ :bank_account => response }, api_key, true)
      bank_account
    end

    def self.retrieve(id, api_key=nil)
      raise NotImplementedError.new("Bank accounts cannot be retrieved without a customer ID. Retrieve a bank account using customer.bank_accounts.retrieve('bank_account_id')")
    end

    private
    def verify_url
      url + '/verify'
    end
  end

  class Customer
    def find_bank_account(bank_account_id)
      response, api_key = Stripe.request(:get, "#{bank_accounts_url}/#{CGI.escape(bank_account_id)}", @api_key)
      return BankAccount.new(response[:id], @api_key).tap do |bank_account|
        bank_account.refresh_from(response.merge(customer: id), @api_key)
      end
    end

    def bank_accounts
      response, api_key = Stripe.request(:get, bank_accounts_url, @api_key)
      refresh_from({ :bank_accounts => response }, api_key, true)
      bank_accounts.map do |bank_account_response|
        ba = BankAccount.new(bank_account_response.id, @api_key)
        ba.refresh_from(bank_account_response.merge(customer: id), @api_key)
      end
    end

    def create_bank_account(params)
      response, api_key = Stripe.request(:post, bank_accounts_url, @api_key, params)
      Util.convert_to_stripe_object(response, api_key)
    end

    private
    def bank_accounts_url
      url + '/bank_accounts'
    end
  end
end
