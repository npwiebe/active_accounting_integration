# frozen_string_literal: true

module ActiveAccountingIntegration
  module Quickbooks
    class MetaData < Shale::Mapper
      attribute :create_time, Shale::Type::String
      attribute :last_updated_time, Shale::Type::String

      json do
        map "CreateTime", to: :create_time
        map "LastUpdatedTime", to: :last_updated_time
      end
    end
  end
end
