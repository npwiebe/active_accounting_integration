# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class Line < Shale::Mapper
      attribute :id, Shale::Type::String
      attribute :line_num, Shale::Type::Integer
      attribute :description, Shale::Type::String
      attribute :amount, Shale::Type::Float
      attribute :linked_txn, Shale::Type::Value

      json do
        map "Id", to: :id
        map "LineNum", to: :line_num
        map "Description", to: :description
        map "Amount", to: :amount
        map "LinkedTxn", to: :linked_txn
      end
    end
  end
end
