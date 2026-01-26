# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class QueryResponse < Shale::Mapper
      attribute :payments, Payment, collection: true
      attribute :customers, Customer, collection: true
      attribute :invoices, Invoice, collection: true

      json do
        map "Payment", to: :payments
        map "Customer", to: :customers
        map "Invoice", to: :invoices
      end
    end
  end
end
