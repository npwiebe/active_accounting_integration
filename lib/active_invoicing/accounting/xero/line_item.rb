# frozen_string_literal: true

require "shale"

module ActiveInvoicing
  module Accounting
    module Xero
      class LineItem < Shale::Mapper
        attribute :line_item_id, Shale::Type::String
        attribute :description, Shale::Type::String
        attribute :quantity, Shale::Type::Float
        attribute :unit_amount, Shale::Type::Float
        attribute :item_code, Shale::Type::String
        attribute :account_code, Shale::Type::String
        attribute :tax_type, Shale::Type::String
        attribute :tax_amount, Shale::Type::Float
        attribute :line_amount, Shale::Type::Float
        attribute :discount_rate, Shale::Type::Float
        attribute :discount_amount, Shale::Type::Float
        attribute :tracking, Shale::Type::Value

        json do
          map "LineItemID", to: :line_item_id
          map "Description", to: :description
          map "Quantity", to: :quantity
          map "UnitAmount", to: :unit_amount
          map "ItemCode", to: :item_code
          map "AccountCode", to: :account_code
          map "TaxType", to: :tax_type
          map "TaxAmount", to: :tax_amount
          map "LineAmount", to: :line_amount
          map "DiscountRate", to: :discount_rate
          map "DiscountAmount", to: :discount_amount
          map "Tracking", to: :tracking
        end
      end
    end
  end
end
