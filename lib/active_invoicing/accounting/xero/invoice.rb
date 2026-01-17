# frozen_string_literal: true

require "json"
require "active_support"
require_relative "contact_reference"
require_relative "line_item"
require_relative "date_type"

module ActiveInvoicing
  module Accounting
    module Xero
      class Invoice < ActiveInvoicing::Accounting::BaseAccountingModel
        attribute :amount_credited, Shale::Type::Float
        attribute :amount_due, Shale::Type::Float
        attribute :amount_paid, Shale::Type::Float
        attribute :branding_theme_id, Shale::Type::String
        attribute :contact, ContactReference
        attribute :credit_notes, Shale::Type::Value
        attribute :currency_code, Shale::Type::String
        attribute :currency_rate, Shale::Type::Float
        attribute :date, DateType
        attribute :due_date, DateType
        attribute :expected_payment_date, DateType
        attribute :fully_paid_on_date, DateType
        attribute :has_attachments, Shale::Type::Boolean
        attribute :has_errors, Shale::Type::Boolean
        attribute :invoice_id, Shale::Type::String
        attribute :invoice_number, Shale::Type::String
        attribute :is_discounted, Shale::Type::Boolean
        attribute :line_amount_types, Shale::Type::String
        attribute :line_items, LineItem, collection: true
        attribute :overpayments, Shale::Type::Value
        attribute :payments, Shale::Type::Value
        attribute :planned_payment_date, DateType
        attribute :prepayments, Shale::Type::Value
        attribute :reference, Shale::Type::String
        attribute :sent_to_contact, Shale::Type::Boolean
        attribute :status, Shale::Type::String
        attribute :sub_total, Shale::Type::Float
        attribute :total, Shale::Type::Float
        attribute :total_discount, Shale::Type::Float
        attribute :total_tax, Shale::Type::Float
        attribute :type, Shale::Type::String
        attribute :updated_date_utc, Shale::Type::String
        attribute :url, Shale::Type::String

        json do
          map "AmountCredited", to: :amount_credited
          map "AmountDue", to: :amount_due
          map "AmountPaid", to: :amount_paid
          map "BrandingThemeID", to: :branding_theme_id
          map "Contact", to: :contact
          map "CreditNotes", to: :credit_notes
          map "CurrencyCode", to: :currency_code
          map "CurrencyRate", to: :currency_rate
          map "Date", to: :date
          map "DueDate", to: :due_date
          map "ExpectedPaymentDate", to: :expected_payment_date
          map "FullyPaidOnDate", to: :fully_paid_on_date
          map "HasAttachments", to: :has_attachments
          map "HasErrors", to: :has_errors
          map "InvoiceID", to: :invoice_id
          map "InvoiceNumber", to: :invoice_number
          map "IsDiscounted", to: :is_discounted
          map "LineAmountTypes", to: :line_amount_types
          map "LineItems", to: :line_items
          map "Overpayments", to: :overpayments
          map "Payments", to: :payments
          map "PlannedPaymentDate", to: :planned_payment_date
          map "Prepayments", to: :prepayments
          map "Reference", to: :reference
          map "SentToContact", to: :sent_to_contact
          map "Status", to: :status
          map "SubTotal", to: :sub_total
          map "Total", to: :total
          map "TotalDiscount", to: :total_discount
          map "TotalTax", to: :total_tax
          map "Type", to: :type
          map "UpdatedDateUTC", to: :updated_date_utc
          map "Url", to: :url
        end

        private

        def update_sync_token(response)
          parsed = JSON.parse(response.body)
          self.updated_date_utc = parsed.dig("Invoices", 0, "UpdatedDateUTC")
        end

        def push_to_source
          @push_response = connection.request(:post, invoice_url, { body: to_json })
          if @push_response.response.success?
            @persisted = true
            update_sync_token(@push_response.response)
            true
          else
            # TODO: Handle error response
            false
          end
        end

        def invoice_url
          self.class.invoice_url
        end

        class << self
          def fetch_by_id(id, connection)
            return unless id && connection&.is_a?(ActiveInvoicing::Accounting::Xero::Connection)

            response = connection.request(:get, "#{invoice_url}/#{id}")
            mapped_response = Response.from_json(response.body)
            invoice = mapped_response.invoices&.first
            return unless invoice

            invoice.instance_variable_set(:@persisted, true)
            invoice.instance_variable_set(:@connection, connection)
            invoice
          end

          def fetch_all(connection)
            return unless connection&.is_a?(ActiveInvoicing::Accounting::Xero::Connection)

            response = connection.request(:get, invoice_url)
            mapped_response = Response.from_json(response.body)
            return [] unless mapped_response.invoices.present?

            mapped_response.invoices.each do |invoice|
              invoice.instance_variable_set(:@persisted, true)
              invoice.instance_variable_set(:@connection, connection)
            end

            mapped_response.invoices
          end

          def invoice_url
            "/api.xro/2.0/Invoices"
          end
        end
      end
    end
  end
end
