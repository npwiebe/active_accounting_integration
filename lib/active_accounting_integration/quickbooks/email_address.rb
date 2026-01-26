# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class EmailAddress < Shale::Mapper
      attribute :address, Shale::Type::String

      json do
        map "Address", to: :address
      end
    end
  end
end
