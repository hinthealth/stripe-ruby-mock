module StripeMock
  module RequestHandlers
    module Tokens

      def Tokens.included(klass)
        klass.add_handler 'post /v1/tokens',      :create_token
        klass.add_handler 'get /v1/tokens/(.*)',  :get_token
      end

      def create_token(route, method_url, params, headers)
        if params[:customer].nil? && params[:card].nil? && params[:bank_account].nil?
          raise Stripe::InvalidRequestError.new('You must supply either a card, customer, or bank account to create a token.', nil, 400)
        end

        cus_id = params[:customer]

        if cus_id && params[:card]
          customer = assert_existance :customer, cus_id, customers[cus_id]

          # params[:card] is an id; grab it from the db
          customer_card = get_card(customer, params[:card])
          assert_existance :card, params[:card], customer_card
        elsif params[:card]
          # params[:card] is a hash of cc info; "Sanitize" the card number
          params[:card][:fingerprint] = StripeMock::Util.fingerprint(params[:card][:number])
          params[:card][:last4] = params[:card][:number][-4,4]
          customer_card = params[:card]
        elsif !params[:bank_account]
          customer = assert_existance :customer, cus_id, customers[cus_id]
          customer_card = get_card(customer, customer[:default_card])
        end

        if params[:bank_account]
          # params[:card] is a hash of cc info; "Sanitize" the card number
          params[:bank_account][:fingerprint] = StripeMock::Util.fingerprint(params[:bank_account][:account_number])
          params[:bank_account][:last4] = params[:bank_account][:account_number][-4,4]
          customer_bank_account = params[:bank_account]

          token_id = generate_bank_token(customer_bank_account)
          bank_account = @bank_tokens[token_id]
        else
          token_id = generate_card_token(customer_bank_account || customer_card)
          card = @card_tokens[token_id]
        end


        Data.mock_token(params.merge :id => token_id, :card => card, bank_account: bank_account)
      end

      def get_token(route, method_url, params, headers)
        route =~ method_url
        # A Stripe token can be either a bank token or a card token
        bank_or_card = @bank_tokens[$1] || @card_tokens[$1]
        assert_existance :token, $1, bank_or_card

        if bank_or_card[:object] == 'card'
          Data.mock_token(:id => $1, :card => bank_or_card)
        elsif bank_or_card[:object] == 'bank_account'
          Data.mock_token(:id => $1, :bank_account => bank_or_card)
        end
      end
    end
  end
end
