# frozen_string_literal: true

require "shale"

module ActiveInvoicing
  module Accounting
    module Xero
      class Address < Shale::Mapper
        attribute :address_type, Shale::Type::String
        attribute :address_line1, Shale::Type::String
        attribute :address_line2, Shale::Type::String
        attribute :address_line3, Shale::Type::String
        attribute :address_line4, Shale::Type::String
        attribute :city, Shale::Type::String
        attribute :region, Shale::Type::String
        attribute :postal_code, Shale::Type::String
        attribute :country, Shale::Type::String
        attribute :attention_to, Shale::Type::String

        json do
          map "AddressType", to: :address_type
          map "AddressLine1", to: :address_line1
          map "AddressLine2", to: :address_line2
          map "AddressLine3", to: :address_line3
          map "AddressLine4", to: :address_line4
          map "City", to: :city
          map "Region", to: :region
          map "PostalCode", to: :postal_code
          map "Country", to: :country
          map "AttentionTo", to: :attention_to
        end
      end
    end
  end
end
