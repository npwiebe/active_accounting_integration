# frozen_string_literal: true

require "json"
require "active_support"
require_relative "meta_data"
require_relative "telephone_number"
require_relative "email_address"
require_relative "web_site_address"
require_relative "physical_address"
require_relative "base_reference"

module ActiveAccountingIntegration
  module Quickbooks
    class Customer < ActiveAccountingIntegration::BaseAccountingModel
      attribute :active, Shale::Type::Boolean
      attribute :alternate_phone, TelephoneNumber
      attribute :balance, Shale::Type::Float
      attribute :balance_with_jobs, Shale::Type::Float
      attribute :bill_with_parent, Shale::Type::Boolean
      attribute :billing_address, PhysicalAddress
      attribute :company_name, Shale::Type::String
      attribute :currency_ref, BaseReference
      attribute :customer_type_ref, BaseReference
      attribute :default_tax_code_ref, BaseReference
      attribute :display_name, Shale::Type::String
      attribute :fax_phone, TelephoneNumber
      attribute :family_name, Shale::Type::String
      attribute :fully_qualified_name, Shale::Type::String
      attribute :given_name, Shale::Type::String
      attribute :id, Shale::Type::String
      attribute :isproject, Shale::Type::Boolean
      attribute :job, Shale::Type::String
      attribute :level, Shale::Type::Integer
      attribute :meta_data, MetaData
      attribute :middle_name, Shale::Type::String
      attribute :mobile_phone, TelephoneNumber
      attribute :notes, Shale::Type::String
      attribute :open_balance_date, Shale::Type::Date
      attribute :parent_ref, BaseReference
      attribute :payment_method_ref, BaseReference
      attribute :preferred_delivery_method, Shale::Type::String
      attribute :primary_email_address, EmailAddress
      attribute :primary_phone, TelephoneNumber
      attribute :primary_tax_identifier, Shale::Type::String
      attribute :print_on_check_name, Shale::Type::String
      attribute :resale_num, Shale::Type::String
      attribute :sales_term_ref, BaseReference
      attribute :shipping_address, PhysicalAddress
      attribute :suffix, Shale::Type::String
      attribute :sync_token, Shale::Type::Integer
      attribute :tax_exemption_reason_id, Shale::Type::String
      attribute :taxable, Shale::Type::Boolean
      attribute :title, Shale::Type::String
      attribute :web_site, WebSiteAddress

      json do
        map "Active", to: :active
        map "AlternatePhone", to: :alternate_phone
        map "Balance", to: :balance
        map "BalanceWithJobs", to: :balance_with_jobs
        map "BillAddr", to: :billing_address
        map "BillWithParent", to: :bill_with_parent
        map "CompanyName", to: :company_name
        map "CurrencyRef", to: :currency_ref
        map "CustomerTypeRef", to: :customer_type_ref
        map "DefaultTaxCodeRef", to: :default_tax_code_ref
        map "DisplayName", to: :display_name
        map "Fax", to: :fax_phone
        map "FamilyName", to: :family_name
        map "FullyQualifiedName", to: :fully_qualified_name
        map "GivenName", to: :given_name
        map "Id", to: :id
        map "IsProject", to: :isproject
        map "Job", to: :job
        map "Level", to: :level
        map "MetaData", to: :meta_data
        map "MiddleName", to: :middle_name
        map "Mobile", to: :mobile_phone
        map "Notes", to: :notes
        map "OpenBalanceDate", to: :open_balance_date
        map "ParentRef", to: :parent_ref
        map "PaymentMethodRef", to: :payment_method_ref
        map "PreferredDeliveryMethod", to: :preferred_delivery_method
        map "PrimaryEmailAddr", to: :primary_email_address
        map "PrimaryPhone", to: :primary_phone
        map "PrimaryTaxIdentifier", to: :primary_tax_identifier
        map "PrintOnCheckName", to: :print_on_check_name
        map "ResaleNum", to: :resale_num
        map "SalesTermRef", to: :sales_term_ref
        map "ShipAddr", to: :shipping_address
        map "Suffix", to: :suffix
        map "SyncToken", to: :sync_token
        map "TaxExemptionReasonId", to: :tax_exemption_reason_id
        map "Taxable", to: :taxable
        map "Title", to: :title
        map "WebAddr", to: :web_site
      end

      private

      def update_sync_token(response)
        self.sync_token = JSON.parse(response.body)["Customer"]["SyncToken"]
      end

      def push_to_source
        @push_response = connection.request(:post, customer_url_builder, { body: to_json })
        if @push_response.response.success?
          @persisted = true
          update_sync_token(@push_response.response)
          true
        else
          # TODO: Handle error response
          false
        end
      end

      def customer_url_builder
        self.class.customer_url_builder(connection)
      end

      class << self
        def fetch_by_id(id, connection)
          return unless id && connection&.is_a?(ActiveAccountingIntegration::Quickbooks::Connection)

          response = connection.request(:get, "/v3/company/#{connection.realm_id}/customer/#{id}")
          mapped_response = Response.from_json(response.body)
          customer = mapped_response.customer
          return unless customer

          customer.instance_variable_set(:@persisted, true)
          customer.instance_variable_set(:@connection, connection)
          customer
        end

        def fetch_all(connection)
          return unless connection&.is_a?(ActiveAccountingIntegration::Quickbooks::Connection)

          response = connection.request(:get, "/v3/company/#{connection.realm_id}/query?query=select * from Customer")
          mapped_query_response = Response.from_json(response.body).query_response
          return [] unless mapped_query_response.try(:customers).present?

          mapped_query_response.customers.each do |customer|
            customer.instance_variable_set(:@persisted, true)
            customer.instance_variable_set(:@connection, connection)
          end

          mapped_query_response.customers
        end

        def customer_url_builder(connection, query: nil)
          url = "/v3/company/#{connection.realm_id}"
          url += if query
            "/query?query=#{query}"
          else
            "/customer/"
          end

          url
        end
      end
    end
  end
end
