# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class CustomField < Shale::Mapper
      attribute :definition_id, Shale::Type::String
      attribute :name, Shale::Type::String
      attribute :type, Shale::Type::String
      attribute :string_value, Shale::Type::String

      json do
        map "DefinitionId", to: :definition_id
        map "Name", to: :name
        map "Type", to: :type
        map "StringValue", to: :string_value
      end
    end
  end
end
