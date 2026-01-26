# frozen_string_literal: true

require "active_support"
require_relative "meta_data"
require_relative "base_reference"
require_relative "physical_address"
require_relative "email_address"
require_relative "line_item"
require_relative "custom_field"
require_relative "delivery_info"
require_relative "linked_transaction"
require_relative "txn_tax_detail"

module ActiveAccountingIntegration
  module Quickbooks
    class Invoice < ActiveAccountingIntegration::BaseAccountingModel
      attribute :allow_ipn_payment, Shale::Type::Boolean
      attribute :allow_online_ach_payment, Shale::Type::Boolean
      attribute :allow_online_credit_card_payment, Shale::Type::Boolean
      attribute :allow_online_payment, Shale::Type::Boolean
      attribute :ar_account_ref, BaseReference
      attribute :apply_tax_after_discount, Shale::Type::Boolean
      attribute :auto_doc_number, Shale::Type::Boolean
      attribute :balance, Shale::Type::Float
      attribute :bill_email, EmailAddress
      attribute :bill_email_cc, EmailAddress
      attribute :billing_address, PhysicalAddress
      attribute :class_ref, BaseReference
      attribute :custom_fields, CustomField, collection: true
      attribute :currency_ref, BaseReference
      attribute :customer_memo, Shale::Type::String
      attribute :customer_ref, BaseReference
      attribute :department_ref, BaseReference
      attribute :deposit, Shale::Type::Float
      attribute :deposit_to_account_ref, BaseReference
      attribute :delivery_info, DeliveryInfo
      attribute :doc_number, Shale::Type::String
      attribute :due_date, Shale::Type::Date
      attribute :domain, Shale::Type::String
      attribute :email_status, Shale::Type::String
      attribute :exchange_rate, Shale::Type::Float
      attribute :home_balance, Shale::Type::Float
      attribute :home_total, Shale::Type::Float
      attribute :id, Shale::Type::String
      attribute :invoice_link, Shale::Type::String
      attribute :line_items, LineItem, collection: true
      attribute :linked_transactions, LinkedTransaction, collection: true
      attribute :meta_data, MetaData
      attribute :private_note, Shale::Type::String
      attribute :print_status, Shale::Type::String
      attribute :sales_term_ref, BaseReference
      attribute :ship_date, Shale::Type::Date
      attribute :ship_from_address, PhysicalAddress
      attribute :ship_method_ref, BaseReference
      attribute :shipping_address, PhysicalAddress
      attribute :sync_token, Shale::Type::Integer
      attribute :total, Shale::Type::Float
      attribute :tracking_num, Shale::Type::String
      attribute :txn_date, Shale::Type::Date
      attribute :txn_tax_detail, TxnTaxDetail

      json do
        map "AllowIPNPayment", to: :allow_ipn_payment
        map "AllowOnlineACHPayment", to: :allow_online_ach_payment
        map "AllowOnlineCreditCardPayment", to: :allow_online_credit_card_payment
        map "AllowOnlinePayment", to: :allow_online_payment
        map "ARAccountRef", to: :ar_account_ref
        map "ApplyTaxAfterDiscount", to: :apply_tax_after_discount
        map "AutoDocNumber", to: :auto_doc_number
        map "Balance", to: :balance
        map "BillEmail", to: :bill_email
        map "BillEmailCc", to: :bill_email_cc
        map "BillAddr", to: :billing_address
        map "ClassRef", to: :class_ref
        map "CustomField", to: :custom_fields
        map "CurrencyRef", to: :currency_ref
        map "CustomerMemo", to: :customer_memo
        map "CustomerRef", to: :customer_ref
        map "DepartmentRef", to: :department_ref
        map "Deposit", to: :deposit
        map "DepositToAccountRef", to: :deposit_to_account_ref
        map "DeliveryInfo", to: :delivery_info
        map "DocNumber", to: :doc_number
        map "DueDate", to: :due_date
        map "domain", to: :domain
        map "EmailStatus", to: :email_status
        map "ExchangeRate", to: :exchange_rate
        map "HomeBalance", to: :home_balance
        map "HomeTotalAmt", to: :home_total
        map "Id", to: :id
        map "InvoiceLink", to: :invoice_link
        map "Line", to: :line_items
        map "LinkedTxn", to: :linked_transactions
        map "MetaData", to: :meta_data
        map "PrivateNote", to: :private_note
        map "PrintStatus", to: :print_status
        map "SalesTermRef", to: :sales_term_ref
        map "ShipDate", to: :ship_date
        map "ShipFromAddr", to: :ship_from_address
        map "ShipMethodRef", to: :ship_method_ref
        map "ShipAddr", to: :shipping_address
        map "SyncToken", to: :sync_token
        map "TotalAmt", to: :total
        map "TrackingNum", to: :tracking_num
        map "TxnDate", to: :txn_date
        map "TxnTaxDetail", to: :txn_tax_detail
      end

      def update_sync_token(response)
        self.sync_token = JSON.parse(response.body)["Invoice"]["SyncToken"]
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
        self.class.invoice_url(connection)
      end

      class << self
        def fetch_by_id(id, connection, join_customer: false)
          return unless id && connection&.is_a?(ActiveAccountingIntegration::Quickbooks::Connection)

          response = connection.request(:get, "#{invoice_url(connection)}#{id}")
          mapped_response = Response.from_json(response.body)
          invoice = mapped_response.invoice
          return unless invoice

          invoice.instance_variable_set(:@persisted, true)
          invoice.instance_variable_set(:@connection, connection)
          invoice
        end

        def fetch_all(connection)
          return unless connection&.is_a?(ActiveAccountingIntegration::Quickbooks::Connection)

          response = connection.request(:get, query_url(connection))
          mapped_query_response = Response.from_json(response.body).query_response
          return [] unless mapped_query_response.try(:invoices).present?

          mapped_query_response.invoices.each do |invoice|
            invoice.instance_variable_set(:@persisted, true)
            invoice.instance_variable_set(:@connection, connection)
          end

          mapped_query_response.invoices
        end

        def invoice_url(connection)
          "/v3/company/#{connection.realm_id}/invoice/"
        end

        def query_url(connection)
          "/v3/company/#{connection.realm_id}/query?query=select * from Invoice"
        end
      end
    end
  end
end
