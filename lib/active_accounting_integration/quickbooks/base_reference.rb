# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class BaseReference < Shale::Mapper
      attribute :value, Shale::Type::String
      attribute :name, Shale::Type::String

      json do
        map "value", to: :value
        map "name", to: :name
      end
    end
  end
end
