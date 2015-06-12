module StripeMock
  module RequestHandlers
    module Helpers
      CARD_TOKEN_PREFIX = 'tok'
      BANK_TOKEN_PREFIX = 'btok'
      def generate_bank_token(bank_params)
        token = new_id BANK_TOKEN_PREFIX
        bank_params[:id] = new_id 'bank'
        @bank_tokens[token] = Data.mock_bank_account symbolize_names(bank_params)
        token
      end

      def generate_card_token(card_params)
        token = new_id CARD_TOKEN_PREFIX
        card_params[:id] = new_id 'cc'
        @card_tokens[token] = Data.mock_card symbolize_names(card_params)
        token
      end

      def get_source_by_token(token)
        if token.nil? || token.starts_with?(CARD_TOKEN_PREFIX)
          get_card_by_token(token)
        else
          get_bank_by_token(token)
        end
      end

      def get_bank_by_token(token)
        if token.nil? || @bank_tokens[token].nil?
          Data.mock_bank_account
        else
          @bank_tokens.delete(token)
        end
      end

      def get_card_by_token(token)
        if token.nil? || @card_tokens[token].nil?
          # TODO: Make this strict
          msg = "Invalid token id: #{token}"
          raise Stripe::InvalidRequestError.new(msg, 'tok', 404)
        else
          @card_tokens.delete(token)
        end
      end

    end
  end
end
