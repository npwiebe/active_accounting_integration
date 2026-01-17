# frozen_string_literal: true

require "shale"

module ActiveInvoicing
  module Accounting
    module Xero
      class AccountReference < Shale::Mapper
        attribute :account_id, Shale::Type::String
        attribute :code, Shale::Type::String
        attribute :name, Shale::Type::String

        json do
          map "AccountID", to: :account_id
          map "Code", to: :code
          map "Name", to: :name
        end
      end
    end
  end
end
