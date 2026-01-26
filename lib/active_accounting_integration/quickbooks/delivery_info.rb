# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class DeliveryInfo < Shale::Mapper
      attribute :delivery_type, Shale::Type::String
      attribute :delivery_time, Shale::Type::String

      json do
        map "DeliveryType", to: :delivery_type
        map "DeliveryTime", to: :delivery_time
      end
    end
  end
end
