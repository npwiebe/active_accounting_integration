# frozen_string_literal: true

require "oauth2"

module ActiveInvoicing
  module Accounting
    module Xero
      class Connection
        XERO_OAUTH_DEFAULTS = {
          site: "https://login.xero.com",
          authorize_url: "https://login.xero.com/identity/connect/authorize",
          token_url: "https://identity.xero.com/connect/token",
        }

        XERO_OAUTH_REQUEST_DEFAULTS = {
          scope: "offline_access accounting.transactions accounting.contacts accounting.settings",
          response_type: "code",
          grant_type: "authorization_code",
          production_domain: "https://api.xero.com",
          sandbox_domain: "https://api.xero.com",
        }

        attr_reader :client_id, :client_secret, :redirect_uri, :tenant_id, :scope, :code, :tokens
        attr_writer :tenant_id

        def initialize(redirect_uri, scope = XERO_OAUTH_REQUEST_DEFAULTS[:scope], client_id = nil, client_secret = nil)
          @client_id = client_id || ActiveInvoicing.configuration.xero_client_id
          @client_secret = client_secret || ActiveInvoicing.configuration.xero_client_secret
          @redirect_uri = redirect_uri
          @scope = scope

          @client = OAuth2::Client.new(@client_id, @client_secret, **XERO_OAUTH_DEFAULTS)
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
          ActiveInvoicing.configuration.sandbox_mode ? XERO_OAUTH_REQUEST_DEFAULTS[:sandbox_domain] : XERO_OAUTH_REQUEST_DEFAULTS[:production_domain]
        end

        def fetch_tenants
          return unless @tokens

          response = request(:get, "https://api.xero.com/connections")
          JSON.parse(response.body)
        end

        def fetch_contact_by_id(id)
          ActiveInvoicing::Accounting::Xero::Contact.fetch_by_id(id, self)
        end

        def fetch_all_contacts
          ActiveInvoicing::Accounting::Xero::Contact.fetch_all(self)
        end

        def fetch_invoice_by_id(id)
          ActiveInvoicing::Accounting::Xero::Invoice.fetch_by_id(id, self)
        end

        def fetch_all_invoices
          ActiveInvoicing::Accounting::Xero::Invoice.fetch_all(self)
        end

        def fetch_payment_by_id(id)
          ActiveInvoicing::Accounting::Xero::Payment.fetch_by_id(id, self)
        end

        def fetch_all_payments
          ActiveInvoicing::Accounting::Xero::Payment.fetch_all(self)
        end

        def request(verb, path, opts = {})
          refresh_access_token if @tokens.expired?

          opts[:headers] ||= {}
          opts[:headers]["Content-Type"] ||= "application/json"
          opts[:headers]["Accept"] ||= "application/json"
          opts[:headers]["Xero-tenant-id"] = @tenant_id if @tenant_id

          uri = URI.join(domain, path) unless opts[:absolute_path]
          @tokens.request(verb, uri, opts)
        end

        def parse_token_url(url)
          uri = URI.parse(url)
          params = URI.decode_www_form(uri.query).to_h
          get_token(params["code"])

          tenants = fetch_tenants
          @tenant_id = tenants.first["tenantId"] if tenants&.any?

          self
        end
      end
    end
  end
end
