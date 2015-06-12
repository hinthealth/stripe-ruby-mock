module StripeMock
  module RequestHandlers
    module Helpers

      def get_bank_account(object, bank_account_id, class_name='Customer')
        bank_accounts = object[:bank_accounts] || object[:sources]
        bank_account = bank_accounts.find{|bank| bank[:id] == bank_account_id }
        if bank_account.nil?
          msg = "#{class_name} #{object[:id]} does not have bank_account #{bank_account_id}"
          raise Stripe::InvalidRequestError.new(msg, 'bank_account', 404)
        end
        bank_account
      end

      def add_bank_account_to_object(type, bank_account, object, replace_current=false)
        bank_account[type] = object[:id]
        bank_accounts = object[:bank_accounts]

        if replace_current
          bank_accounts[:data].delete_if {|bank_account| bank_account[:id] == object[:default_bank_account]}
          object[:default_bank_account] = object[:default_source] = bank_account[:id]
          object[:default_source_type] = 'bank_account'
          object[:sources][:data] = bank_accounts[:data] = [bank_account]
        else
          bank_accounts[:total_count] += 1
          bank_accounts[:data] << bank_account
        end

        object[:sources][:data] = object[:sources][:data] | object[:bank_accounts][:data]

        if object[:default_source].nil?
          object[:default_source] = object[:default_bank_account] = bank_account[:id]
          object[:default_source_type] = 'bank_account'
        end

        bank_account
      end

      def retrieve_object_bank_accounts(type, type_id, objects)
        resource = assert_existence type, type_id, objects[type_id]
        bank_accounts = resource[:bank_accounts] || resource[:sources]

        Data.mock_list_object(bank_accounts[:data])
      end

      def delete_bank_account_from(type, type_id, bank_account_id, objects)
        resource = assert_existence type, type_id, objects[type_id]

        assert_existence :bank_account, bank_account_id, get_bank_account(resource, bank_account_id)

        bank_account = { id: bank_account_id, deleted: true }
        resource[:bank_accounts][:data].reject!{|cc|
          cc[:id] == bank_account[:id]
        }
        resource[:sources][:data].reject!{|cc|
          cc[:id] == bank_account[:id]
        }

        new_default = resource[:sources][:data].count > 0 ? resource[:sources][:data].first[:id] : nil
        resource[:default_source] = resource[:default_bank_account] = new_default
        bank_account
      end

      def add_bank_account_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]

        bank_account = bank_account_from_params(params[:bank_account] || params[:source])
        add_bank_account_to_object(type, bank_account, resource)
      end

      def validate_bank_account(bank_account)
        [:routing_number, :account_number].each do |field|
          bank_account[field] = bank_account[field].to_i
        end
        bank_account
      end

      def bank_account_from_params(attrs_or_token)
        if attrs_or_token.is_a? Hash
          attrs_or_token = generate_bank_account_token(attrs_or_token)
        end
        bank_account = get_bank_account_by_token(attrs_or_token)
        validate_bank_account(bank_account)
      end

    end
  end
end
