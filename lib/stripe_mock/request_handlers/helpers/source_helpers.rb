module StripeMock
  module RequestHandlers
    module Helpers
      def get_source(object, source_id, class_name='Customer')
        sources = object[:sources]
        source = sources[:data].find{|source| source[:id] == source_id }
        if source.nil?
          if class_name == 'Recipient'
            msg = "#{class_name} #{object[:id]} does not have a source with ID #{source_id}"
            raise Stripe::InvalidRequestError.new(msg, 'source', 404)
          else
            msg = "There is no source with ID #{source_id}"
            raise Stripe::InvalidRequestError.new(msg, 'id', 404)
          end
        end
        source
      end

      def retrieve_object_sources(type, type_id, objects)
        resource = assert_existence type, type_id, objects[type_id]

        Data.mock_list_object(resource[:sources][:data])
      end

      def delete_source_from(type, type_id, source_id, objects)
        resource = assert_existence type, type_id, objects[type_id]

        assert_existence :source, source_id, get_source(resource, source_id)

        source = { id: source_id, deleted: true }
        sources_or_sources = resource[:sources]
        sources_or_sources[:data].reject!{|cc|
          cc[:id] == source[:id]
        }

        is_customer = resource.has_key?(:sources)
        new_default = sources_or_sources[:data].count > 0 ? sources_or_sources[:data].first[:id] : nil
        resource[:default_source] = new_default unless is_customer
        resource[:default_source] = new_default if is_customer
        source
      end

      def add_source_to(type, type_id, params, objects)
        resource = assert_existence type, type_id, objects[type_id]
        if source.is_a?(Hash)
          case source[:object]
          when 'bank_account'
            add_bank_account_to(type, type_id, params, objects)
          when 'card'
            add_card_to(type, type_id, params, objects)
          else
            raise "Sources must have an object, and it must be either 'card' or 'bank_account'"
          end
        elsif source.is_a?(String)
          if source.starts_with?('btok')
            add_bank_account_to(type, type_id, params, objects)
          else
            add_card_to(type, type_id, params, objects)
          end
        end
      end


      # get_source(obj, id)
      # delete_source_from
      # add_source_to(:customer, $1, params, customers)
      # retrieve_object_sources(:customer, $1, customers)
      # retrieve_object_sources(type, object, )
    end
  end
end
