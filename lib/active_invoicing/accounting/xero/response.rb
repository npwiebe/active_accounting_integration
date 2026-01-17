# frozen_string_literal: true

require "shale"

module ActiveInvoicing
  module Accounting
    module Xero
      class Response < Shale::Mapper
        attribute :contacts, Contact, collection: true
        attribute :invoices, Invoice, collection: true
        attribute :payments, Payment, collection: true

        json do
          map "Contacts", to: :contacts
          map "Invoices", to: :invoices
          map "Payments", to: :payments
        end
      end
    end
  end
end
