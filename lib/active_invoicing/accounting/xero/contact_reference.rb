# frozen_string_literal: true

require "shale"

module ActiveInvoicing
  module Accounting
    module Xero
      class ContactReference < Shale::Mapper
        attribute :contact_id, Shale::Type::String
        attribute :contact_number, Shale::Type::String
        attribute :name, Shale::Type::String

        json do
          map "ContactID", to: :contact_id
          map "ContactNumber", to: :contact_number
          map "Name", to: :name
        end
      end
    end
  end
end
