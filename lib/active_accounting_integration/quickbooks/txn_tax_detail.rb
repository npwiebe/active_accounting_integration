# frozen_string_literal: true

require "shale"
require_relative "base_reference"

module ActiveAccountingIntegration
  module Quickbooks
    class TxnTaxDetail < Shale::Mapper
      attribute :txn_tax_code_ref, BaseReference
      attribute :total_tax, Shale::Type::Float
      attribute :tax_line, Shale::Type::Value

      json do
        map "TxnTaxCodeRef", to: :txn_tax_code_ref
        map "TotalTax", to: :total_tax
        map "TaxLine", to: :tax_line
      end
    end
  end
end
