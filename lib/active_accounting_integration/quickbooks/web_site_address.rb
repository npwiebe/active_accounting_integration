# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class WebSiteAddress < Shale::Mapper
      attribute :uri, Shale::Type::String

      json do
        map "URI", to: :uri
      end
    end
  end
end
