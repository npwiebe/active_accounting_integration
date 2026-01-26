# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class PhysicalAddress < Shale::Mapper
      attribute :id, Shale::Type::String
      attribute :line1, Shale::Type::String
      attribute :line2, Shale::Type::String
      attribute :line3, Shale::Type::String
      attribute :line4, Shale::Type::String
      attribute :line5, Shale::Type::String
      attribute :city, Shale::Type::String
      attribute :country, Shale::Type::String
      attribute :country_sub_division_code, Shale::Type::String
      attribute :postal_code, Shale::Type::String
      attribute :lat, Shale::Type::String
      attribute :long, Shale::Type::String

      json do
        map "Id", to: :id
        map "Line1", to: :line1
        map "Line2", to: :line2
        map "Line3", to: :line3
        map "Line4", to: :line4
        map "Line5", to: :line5
        map "City", to: :city
        map "Country", to: :country
        map "CountrySubDivisionCode", to: :country_sub_division_code
        map "PostalCode", to: :postal_code
        map "Lat", to: :lat
        map "Long", to: :long
      end
    end
  end
end
