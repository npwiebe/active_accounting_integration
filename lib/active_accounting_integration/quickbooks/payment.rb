# frozen_string_literal: true

module ActiveAccountingIntegration
  module Quickbooks
    class Payment < ActiveAccountingIntegration::BaseAccountingModel
      attribute :ar_account_ref, BaseReference
      attribute :credit_card_payment, CreditCardPayment
      attribute :currency_ref, BaseReference
      attribute :customer_ref, BaseReference
      attribute :deposit_to_account_ref, BaseReference
      attribute :exchange_rate, Shale::Type::Float
      attribute :id, Shale::Type::String
      attribute :line_items, Line, collection: true
      attribute :meta_data, MetaData
      attribute :payment_method_ref, BaseReference
      attribute :payment_ref_number, Shale::Type::String
      attribute :private_note, Shale::Type::String
      attribute :process_payment, Shale::Type::Boolean
      attribute :sync_token, Shale::Type::Integer
      attribute :total, Shale::Type::Float
      attribute :txn_date, Shale::Type::Date
      attribute :txn_status, Shale::Type::String
      attribute :unapplied_amount, Shale::Type::Float

      json do
        map "ARAccountRef", to: :ar_account_ref
        map "CreditCardPayment", to: :credit_card_payment
        map "CurrencyRef", to: :currency_ref
        map "CustomerRef", to: :customer_ref
        map "DepositToAccountRef", to: :deposit_to_account_ref
        map "ExchangeRate", to: :exchange_rate
        map "Id", to: :id
        map "Line", to: :line_items
        map "MetaData", to: :meta_data
        map "PaymentMethodRef", to: :payment_method_ref
        map "PaymentRefNum", to: :payment_ref_number
        map "PrivateNote", to: :private_note
        map "ProcessPayment", to: :process_payment
        map "SyncToken", to: :sync_token
        map "TotalAmt", to: :total
        map "TxnDate", to: :txn_date
        map "TxnStatus", to: :txn_status
        map "UnappliedAmt", to: :unapplied_amount
      end

      private

      def update_sync_token(response)
        self.sync_token = JSON.parse(response.body)["Payment"]["SyncToken"]
      end

      def push_to_source
        @push_response = connection.request(:post, payment_url_builder, { body: to_json })
        if @push_response.response.success?
          @persisted = true
          update_sync_token(@push_response.response)
          true
        else
          # TODO: Handle error response
          false
        end
      end

      def payment_url_builder
        self.class.payment_url_builder(connection)
      end

      class << self
        def fetch_by_id(id, connection)
          return unless id && connection&.is_a?(ActiveAccountingIntegration::Quickbooks::Connection)

          response = connection.request(:get, "/v3/company/#{connection.realm_id}/payment/#{id}")
          mapped_response = Response.from_json(response.body)
          payment = mapped_response.payment
          return unless payment

          payment.instance_variable_set(:@persisted, true)
          payment.instance_variable_set(:@connection, connection)
          payment
        end

        def fetch_all(connection)
          return unless connection&.is_a?(ActiveAccountingIntegration::Quickbooks::Connection)

          response = connection.request(:get, "/v3/company/#{connection.realm_id}/query?query=select * from Payment").response
          mapped_query_response = Response.from_json(response.body).query_response
          return [] unless mapped_query_response.try(:payments).present?

          mapped_query_response.payments.each do |payment|
            payment.instance_variable_set(:@persisted, true)
            payment.instance_variable_set(:@connection, connection)
          end

          mapped_query_response.payments
        end

        def payment_url_builder(connection, query: nil)
          url = "/v3/company/#{connection.realm_id}"
          url += if query
            "/query?query=#{query}"
          else
            "/payment/"
          end

          url
        end
      end
    end
  end
end
