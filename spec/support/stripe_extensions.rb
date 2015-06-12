# require 'stripe'

module Stripe
  class BankAccount
    def verify(params = {}, opts = {})
      response, opts = request(:post, verify_url, params, opts)
      refresh_from(response, opts)
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

end
