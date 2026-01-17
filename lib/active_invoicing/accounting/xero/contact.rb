# frozen_string_literal: true

require "json"
require "active_support"
require_relative "address"
require_relative "phone"

module ActiveInvoicing
  module Accounting
    module Xero
      class Contact < ActiveInvoicing::Accounting::BaseAccountingModel
        attribute :account_number, Shale::Type::String
        attribute :accounts_payable_tax_type, Shale::Type::String
        attribute :accounts_receivable_tax_type, Shale::Type::String
        attribute :addresses, Address, collection: true
        attribute :balances, Shale::Type::Value
        attribute :bank_account_details, Shale::Type::String
        attribute :batch_payments, Shale::Type::Value
        attribute :branding_theme, Shale::Type::Value
        attribute :contact_groups, Shale::Type::Value
        attribute :contact_id, Shale::Type::String
        attribute :contact_number, Shale::Type::String
        attribute :contact_persons, Shale::Type::Value
        attribute :contact_status, Shale::Type::String
        attribute :company_number, Shale::Type::String
        attribute :default_currency, Shale::Type::String
        attribute :discount, Shale::Type::Float
        attribute :email_address, Shale::Type::String
        attribute :first_name, Shale::Type::String
        attribute :has_attachments, Shale::Type::Boolean
        attribute :is_customer, Shale::Type::Boolean
        attribute :is_supplier, Shale::Type::Boolean
        attribute :last_name, Shale::Type::String
        attribute :name, Shale::Type::String
        attribute :phones, Phone, collection: true
        attribute :skype_user_name, Shale::Type::String
        attribute :tax_number, Shale::Type::String
        attribute :updated_date_utc, Shale::Type::String
        attribute :website, Shale::Type::String

        json do
          map "AccountNumber", to: :account_number
          map "AccountsPayableTaxType", to: :accounts_payable_tax_type
          map "AccountsReceivableTaxType", to: :accounts_receivable_tax_type
          map "Addresses", to: :addresses
          map "Balances", to: :balances
          map "BankAccountDetails", to: :bank_account_details
          map "BatchPayments", to: :batch_payments
          map "BrandingTheme", to: :branding_theme
          map "ContactGroups", to: :contact_groups
          map "ContactID", to: :contact_id
          map "ContactNumber", to: :contact_number
          map "ContactPersons", to: :contact_persons
          map "ContactStatus", to: :contact_status
          map "CompanyNumber", to: :company_number
          map "DefaultCurrency", to: :default_currency
          map "Discount", to: :discount
          map "EmailAddress", to: :email_address
          map "FirstName", to: :first_name
          map "HasAttachments", to: :has_attachments
          map "IsCustomer", to: :is_customer
          map "IsSupplier", to: :is_supplier
          map "LastName", to: :last_name
          map "Name", to: :name
          map "Phones", to: :phones
          map "SkypeUserName", to: :skype_user_name
          map "TaxNumber", to: :tax_number
          map "UpdatedDateUTC", to: :updated_date_utc
          map "Website", to: :website
        end

        private

        def update_sync_token(response)
          parsed = JSON.parse(response.body)
          self.updated_date_utc = parsed.dig("Contacts", 0, "UpdatedDateUTC")
        end

        def push_to_source
          @push_response = connection.request(:post, contact_url, { body: to_json })
          if @push_response.response.success?
            @persisted = true
            update_sync_token(@push_response.response)
            true
          else
            # TODO: Handle error response
            false
          end
        end

        def contact_url
          self.class.contact_url
        end

        class << self
          def fetch_by_id(id, connection)
            return unless id && connection&.is_a?(ActiveInvoicing::Accounting::Xero::Connection)

            response = connection.request(:get, "#{contact_url}/#{id}")
            mapped_response = Response.from_json(response.body)
            contact = mapped_response.contacts&.first
            return unless contact

            contact.instance_variable_set(:@persisted, true)
            contact.instance_variable_set(:@connection, connection)
            contact
          end

          def fetch_all(connection)
            return unless connection&.is_a?(ActiveInvoicing::Accounting::Xero::Connection)

            response = connection.request(:get, contact_url)

            mapped_response = Response.from_json(response.body)
            return [] unless mapped_response.contacts.present?

            mapped_response.contacts.each do |contact|
              contact.instance_variable_set(:@persisted, true)
              contact.instance_variable_set(:@connection, connection)
            end

            mapped_response.contacts
          end

          def contact_url
            "/api.xro/2.0/Contacts"
          end
        end
      end
    end
  end
end
