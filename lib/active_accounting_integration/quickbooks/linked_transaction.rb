# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class LinkedTransaction < Shale::Mapper
      attribute :txn_id, Shale::Type::String
      attribute :txn_type, Shale::Type::String
      attribute :txn_line_id, Shale::Type::String

      json do
        map "TxnId", to: :txn_id
        map "TxnType", to: :txn_type
        map "TxnLineId", to: :txn_line_id
      end
    end
  end
end
