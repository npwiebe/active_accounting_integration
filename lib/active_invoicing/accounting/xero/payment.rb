# frozen_string_literal: true

require "json"
require "active_support"
require_relative "invoice_reference"
require_relative "account_reference"
require_relative "date_type"

module ActiveInvoicing
  module Accounting
    module Xero
      class Payment < ActiveInvoicing::Accounting::BaseAccountingModel
        attribute :account, AccountReference
        attribute :amount, Shale::Type::Float
        attribute :batch_payment_id, Shale::Type::String
        attribute :currency_rate, Shale::Type::Float
        attribute :date, DateType
        attribute :has_account, Shale::Type::Boolean
        attribute :has_validation_errors, Shale::Type::Boolean
        attribute :invoice, InvoiceReference
        attribute :is_reconciled, Shale::Type::Boolean
        attribute :payment_id, Shale::Type::String
        attribute :payment_type, Shale::Type::String
        attribute :reference, Shale::Type::String
        attribute :status, Shale::Type::String
        attribute :updated_date_utc, Shale::Type::String

        json do
          map "Account", to: :account
          map "Amount", to: :amount
          map "BatchPaymentID", to: :batch_payment_id
          map "CurrencyRate", to: :currency_rate
          map "Date", to: :date
          map "HasAccount", to: :has_account
          map "HasValidationErrors", to: :has_validation_errors
          map "Invoice", to: :invoice
          map "IsReconciled", to: :is_reconciled
          map "PaymentID", to: :payment_id
          map "PaymentType", to: :payment_type
          map "Reference", to: :reference
          map "Status", to: :status
          map "UpdatedDateUTC", to: :updated_date_utc
        end

        private

        def update_sync_token(response)
          parsed = JSON.parse(response.body)
          self.updated_date_utc = parsed.dig("Payments", 0, "UpdatedDateUTC")
        end

        def push_to_source
          @push_response = connection.request(:post, payment_url, { body: to_json })
          if @push_response.response.success?
            @persisted = true
            update_sync_token(@push_response.response)
            true
          else
            # TODO: Handle error response
            false
          end
        end

        def payment_url
          self.class.payment_url
        end

        class << self
          def fetch_by_id(id, connection)
            return unless id && connection&.is_a?(ActiveInvoicing::Accounting::Xero::Connection)

            response = connection.request(:get, "#{payment_url}/#{id}")
            mapped_response = Response.from_json(response.body)
            payment = mapped_response.payments&.first
            return unless payment

            payment.instance_variable_set(:@persisted, true)
            payment.instance_variable_set(:@connection, connection)
            payment
          end

          def fetch_all(connection)
            return unless connection&.is_a?(ActiveInvoicing::Accounting::Xero::Connection)

            response = connection.request(:get, payment_url)
            mapped_response = Response.from_json(response.body)
            return [] unless mapped_response.payments.present?

            mapped_response.payments.each do |payment|
              payment.instance_variable_set(:@persisted, true)
              payment.instance_variable_set(:@connection, connection)
            end

            mapped_response.payments
          end

          def payment_url
            "/api.xro/2.0/Payments"
          end
        end
      end
    end
  end
end
