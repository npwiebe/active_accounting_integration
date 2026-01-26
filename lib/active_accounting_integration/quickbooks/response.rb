# frozen_string_literal: true

module ActiveAccountingIntegration
  module Quickbooks
    class Response < Shale::Mapper
      attribute :query_response, QueryResponse
      attribute :payment, Payment
      attribute :customer, Customer
      attribute :invoice, Invoice

      json do
        map "QueryResponse", to: :query_response
        map "Payment", to: :payment
        map "Customer", to: :customer
        map "Invoice", to: :invoice
      end
    end
  end
end
