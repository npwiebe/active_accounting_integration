# frozen_string_literal: true

require "oauth2"

module ActiveAccountingIntegration
  module Quickbooks
    class Connection
      QUICKBOOKS_OAUTH_DEFAULTS = {
        site: "https://appcenter.intuit.com/connect/oauth2",
        authorize_url: "https://appcenter.intuit.com/connect/oauth2",
        token_url: "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer",
      }

      QUICKBOOKS_OAUTH_REQUEST_DEFAULTS = {
        scope: "com.intuit.quickbooks.accounting openid profile email phone address",
        response_type: "code",
        grant_type: "authorization_code",
        sandbox_domain: "https://sandbox-quickbooks.api.intuit.com",
        production_domain: "https://quickbooks.api.intuit.com",
      }

      attr_reader :client_id, :client_secret, :redirect_uri, :realm_id, :scope, :code, :tokens
      attr_writer :realm_id

      def initialize(redirect_uri, scope = QUICKBOOKS_OAUTH_REQUEST_DEFAULTS[:scope], client_id = nil, client_secret = nil)
        @client_id = client_id || ActiveAccountingIntegration.configuration.quickbooks_client_id
        @client_secret = client_secret || ActiveAccountingIntegration.configuration.quickbooks_client_secret
        @redirect_uri = redirect_uri
        @scope = scope

        @client = OAuth2::Client.new(@client_id, @client_secret, **QUICKBOOKS_OAUTH_DEFAULTS)
      end

      def authorize_url
        @client.auth_code.authorize_url(redirect_uri: @redirect_uri, scope: @scope, state: SecureRandom.hex(12))
      end

      def get_token(code)
        @tokens = @client.auth_code.get_token(code, redirect_uri: @redirect_uri)
      end

      def access_token
        @tokens&.token
      end

      def refresh_token
        @tokens&.refresh_token
      end

      def refresh_access_token
        @tokens = @tokens.refresh!
      end

      def domain
        ActiveAccountingIntegration.configuration.sandbox_mode ? QUICKBOOKS_OAUTH_REQUEST_DEFAULTS[:sandbox_domain] : QUICKBOOKS_OAUTH_REQUEST_DEFAULTS[:production_domain]
      end

      def fetch_invoice_by_id(id)
        ActiveAccountingIntegration::Quickbooks::Invoice.fetch_by_id(id, self)
      end

      def fetch_all_invoices
        ActiveAccountingIntegration::Quickbooks::Invoice.fetch_all(self)
      end

      def fetch_customer_by_id(id)
        ActiveAccountingIntegration::Quickbooks::Customer.fetch_by_id(id, self)
      end
      alias_method :fetch_contact_by_id, :fetch_customer_by_id

      def fetch_all_customers
        ActiveAccountingIntegration::Quickbooks::Customer.fetch_all(self)
      end
      alias_method :fetch_all_contacts, :fetch_all_customers

      def fetch_payment_by_id(id)
        ActiveAccountingIntegration::Quickbooks::Payment.fetch_by_id(id, self)
      end

      def fetch_all_payments
        ActiveAccountingIntegration::Quickbooks::Payment.fetch_all(self)
      end

      def request(verb, path, opts = {})
        refresh_access_token if @tokens.expired?

        opts[:headers] ||= {}
        opts[:headers]["Content-Type"] ||= "application/json"
        opts[:headers]["Accept"] ||= "application/json"
        uri = URI.join(domain, path) unless opts[:absolute_path]
        @tokens.request(verb, uri, opts)
      end

      def parse_token_url(url)
        uri = URI.parse(url)
        params = URI.decode_www_form(uri.query).to_h
        @realm_id = params["realmId"]
        get_token(params["code"])

        self
      end
    end
  end
end
