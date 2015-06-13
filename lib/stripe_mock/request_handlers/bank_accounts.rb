module StripeMock
  module RequestHandlers
    module BankAccounts

      def BankAccounts.included(klass)
        klass.add_handler 'get /v1/customers/(.*)/bank_accounts', :retrieve_bank_accounts
        klass.add_handler 'post /v1/customers/(.*)/bank_accounts', :create_bank_account
        klass.add_handler 'get /v1/customers/(.*)/bank_accounts/(.*)', :retrieve_bank_account
        klass.add_handler 'post /v1/customers/(.*)/bank_accounts/(.*)/verify', :verify_bank_accounts
        klass.add_handler 'delete /v1/customers/(.*)/bank_accounts/(.*)', :delete_bank_account
        klass.add_handler 'post /v1/customers/(.*)/bank_accounts/(.*)', :update_bank_account
        klass.add_handler 'get /v1/recipients/(.*)/bank_accounts/(.*)', :retrieve_recipient_bank_account
      end

      def create_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        bank_account = bank_account_from_params(params[:bank_account])
        add_bank_account_to_object(:customer, bank_account, customer)
      end

      def retrieve_bank_accounts(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        bank_accounts = customer[:bank_accounts]
        bank_accounts[:count] = bank_accounts[:data].length
        bank_accounts
      end

      def retrieve_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        assert_existence :bank_account, $2, get_bank_account(customer, $2)
      end

      def retrieve_recipient_bank_account(route, method_url, params, headers)
        route =~ method_url
        recipient = assert_existence :recipient, $1, recipients[$1]

        assert_existence :bank_account, $2, get_bank_account(recipient, $2, "Recipient")
      end

      def delete_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        assert_existence :bank_account, $2, get_bank_account(customer, $2)

        bank_account = { id: $2, deleted: true }
        customer[:bank_accounts][:data].reject!{|cc|
          cc[:id] == bank_account[:id]
        }
        customer[:sources][:data].reject!{|cc|
          cc[:id] == bank_account[:id]
        }
        customer[:default_source] = customer[:sources][:data].count > 0 ? customer[:sources][:data].first[:id] : nil
        if customer[:default_source] && customer[:default_source][:object] = 'bank_account'
          customer[:default_bank_account] = customer[:default_source]
        else
          customer[:default_bank_account] = nil
        end

        bank_account
      end

      def update_bank_account(route, method_url, params, headers)
        route =~ method_url
        customer = assert_existence :customer, $1, customers[$1]

        bank_account = assert_existence :bank_account, $2, get_bank_account(customer, $2)
        bank_account.merge!(params)
        bank_account
      end

      def verify_bank_accounts(route, method_url, params, headers)
        route =~ method_url

        customer = customers[$1]
        assert_existence :customer, $1, customer

        bank_account = assert_existence :bank_account, $2, get_bank_account(customer, $2)

        # These are only acceptable deposit amounts for test banks
        if params[:amounts] == [32,45]
          bank_account[:status] = 'verified'
        else
          raise Stripe::InvalidRequestError.new("The verification amounts provided do not match.", "BankAccount", 400)
        end
        bank_account
      end


      private

      def bank_account_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_bank_token(attrs_or_token)
        end
        bank_account = get_bank_by_token(attrs_or_token)
      end
    end
  end
end
