# frozen_string_literal: true

require "shale"

module ActiveAccountingIntegration
  module Quickbooks
    class TelephoneNumber < Shale::Mapper
      attribute :free_form_number, Shale::Type::String

      json do
        map "FreeFormNumber", to: :free_form_number
      end
    end
  end
end
