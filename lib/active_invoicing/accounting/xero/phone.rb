# frozen_string_literal: true

require "shale"

module ActiveInvoicing
  module Accounting
    module Xero
      class Phone < Shale::Mapper
        attribute :phone_type, Shale::Type::String
        attribute :phone_number, Shale::Type::String
        attribute :phone_area_code, Shale::Type::String
        attribute :phone_country_code, Shale::Type::String

        json do
          map "PhoneType", to: :phone_type
          map "PhoneNumber", to: :phone_number
          map "PhoneAreaCode", to: :phone_area_code
          map "PhoneCountryCode", to: :phone_country_code
        end
      end
    end
  end
end
