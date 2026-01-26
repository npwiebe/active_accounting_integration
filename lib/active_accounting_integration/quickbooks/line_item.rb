# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class LineItem < Shale::Mapper
      attribute :id, Shale::Type::String
      attribute :line_num, Shale::Type::Integer
      attribute :description, Shale::Type::String
      attribute :amount, Shale::Type::Float
      attribute :detail_type, Shale::Type::String
      attribute :sales_item_line_detail, Shale::Type::Value
      attribute :discount_line_detail, Shale::Type::Value

      json do
        map "Id", to: :id
        map "LineNum", to: :line_num
        map "Description", to: :description
        map "Amount", to: :amount
        map "DetailType", to: :detail_type
        map "SalesItemLineDetail", to: :sales_item_line_detail
        map "DiscountLineDetail", to: :discount_line_detail
      end
    end
  end
end
