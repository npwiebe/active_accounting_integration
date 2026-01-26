# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class CreditCardPayment < Shale::Mapper
      attribute :credit_charge_info, Shale::Type::Value
      attribute :credit_charge_response, Shale::Type::Value

      json do
        map "CreditChargeInfo", to: :credit_charge_info
        map "CreditChargeResponse", to: :credit_charge_response
      end
    end
  end
end
