# frozen_string_literal: true

require "shale"

module ActiveInvoicing
  module Accounting
    module Xero
      class InvoiceReference < Shale::Mapper
        attribute :invoice_id, Shale::Type::String
        attribute :invoice_number, Shale::Type::String

        json do
          map "InvoiceID", to: :invoice_id
          map "InvoiceNumber", to: :invoice_number
        end
      end
    end
  end
end
