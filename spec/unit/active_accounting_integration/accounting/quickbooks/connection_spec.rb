# frozen_string_literal: true

require "oauth2"
require "securerandom"
require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::Connection) do
  let(:redirect_uri) { "http://example.com/callback" }
  let(:client_id) { "dummy_client_id" }
  let(:client_secret) { "dummy_client_secret" }
  let(:scope) { "com.intuit.quickbooks.accounting" }
  subject(:connection) { described_class.new(redirect_uri, scope, client_id, client_secret) }

  describe "#authorize_url" do
    it "returns a proper OAuth2 authorize URL" do
      dummy_url = "http://dummy.url"
      expect(connection.instance_variable_get(:@client).auth_code)
        .to(receive(:authorize_url)
        .with(hash_including(redirect_uri: redirect_uri, scope: scope, state: kind_of(String)))
        .and_return(dummy_url))

      expect(connection.authorize_url).to(eq(dummy_url))
    end
  end

  describe "#get_token" do
    let(:code) { "dummy_code" }
    let(:dummy_tokens) do
      instance_double(OAuth2::AccessToken, token: "access_token", refresh_token: "refresh_token", refresh!: nil)
    end

    it "stores the tokens obtained from OAuth2" do
      expect(connection.instance_variable_get(:@client).auth_code)
        .to(receive(:get_token)
        .with(code, redirect_uri: redirect_uri)
        .and_return(dummy_tokens))

      connection.get_token(code)
      expect(connection.tokens).to(eq(dummy_tokens))
    end
  end

  describe "#access_token" do
    context "when tokens are set" do
      let(:dummy_tokens) { instance_double(OAuth2::AccessToken, token: "access_token") }

      it "returns the access token" do
        connection.instance_variable_set(:@tokens, dummy_tokens)
        expect(connection.access_token).to(eq("access_token"))
      end
    end

    context "when tokens are nil" do
      it "returns nil" do
        connection.instance_variable_set(:@tokens, nil)
        expect(connection.access_token).to(be_nil)
      end
    end
  end

  describe "#refresh_token" do
    context "when tokens are set" do
      let(:dummy_tokens) { instance_double(OAuth2::AccessToken, refresh_token: "refresh_token") }

      it "returns the refresh token" do
        connection.instance_variable_set(:@tokens, dummy_tokens)
        expect(connection.refresh_token).to(eq("refresh_token"))
      end
    end

    context "when tokens are nil" do
      it "returns nil" do
        connection.instance_variable_set(:@tokens, nil)
        expect(connection.refresh_token).to(be_nil)
      end
    end
  end

  describe "#refresh_access_token" do
    it "updates tokens by refreshing them" do
      dummy_new_tokens = instance_double(OAuth2::AccessToken)
      dummy_tokens = instance_double(OAuth2::AccessToken)
      allow(dummy_tokens).to(receive(:refresh!).and_return(dummy_new_tokens))
      connection.instance_variable_set(:@tokens, dummy_tokens)

      connection.refresh_access_token
      expect(connection.tokens).to(eq(dummy_new_tokens))
    end
  end

  describe "#request" do
    let(:dummy_response) { double("response") }
    let(:dummy_tokens) do
      instance_double(OAuth2::AccessToken, request: dummy_response, expired?: false)
    end

    before { connection.instance_variable_set(:@tokens, dummy_tokens) }

    it "returns the response from the token request" do
      expect(connection.request(:get, "/test/path")).to(eq(dummy_response))
    end

    it "refreshes token if expired" do
      allow(dummy_tokens).to(receive(:expired?).and_return(true))
      allow(dummy_tokens).to(receive(:refresh!).and_return(dummy_tokens))

      connection.request(:get, "/test/path")

      expect(dummy_tokens).to(have_received(:refresh!))
    end

    it "sets default headers" do
      expect(dummy_tokens).to(receive(:request).with(
        :get,
        kind_of(URI),
        hash_including(
          headers: hash_including(
            "Content-Type" => "application/json",
            "Accept" => "application/json",
          ),
        ),
      ))

      connection.request(:get, "/test/path")
    end

    it "preserves existing headers" do
      expect(dummy_tokens).to(receive(:request).with(
        :get,
        kind_of(URI),
        hash_including(
          headers: hash_including(
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "Custom-Header" => "custom_value",
          ),
        ),
      ))

      connection.request(:get, "/test/path", headers: { "Custom-Header" => "custom_value" })
    end
  end

  describe "#domain" do
    context "when sandbox mode is enabled" do
      before do
        allow(ActiveAccountingIntegration.configuration).to(receive(:sandbox_mode).and_return(true))
      end

      it "returns sandbox domain" do
        expect(connection.domain).to(eq("https://sandbox-quickbooks.api.intuit.com"))
      end
    end

    context "when sandbox mode is disabled" do
      before do
        allow(ActiveAccountingIntegration.configuration).to(receive(:sandbox_mode).and_return(false))
      end

      it "returns production domain" do
        expect(connection.domain).to(eq("https://quickbooks.api.intuit.com"))
      end
    end
  end

  describe "#parse_token_url" do
    let(:token_url) { "http://example.com/callback?code=test_code&realmId=123456789" }

    it "extracts code and realm_id from URL" do
      expect(connection.instance_variable_get(:@client).auth_code).to(receive(:get_token)
        .with("test_code", redirect_uri: redirect_uri)
        .and_return(double("tokens")))

      connection.parse_token_url(token_url)

      expect(connection.realm_id).to(eq("123456789"))
    end
  end

  describe "customer methods" do
    it "delegates fetch_customer_by_id to Customer class" do
      expect(ActiveAccountingIntegration::Quickbooks::Customer).to(receive(:fetch_by_id)
        .with("123", connection))

      connection.fetch_customer_by_id("123")
    end

    it "delegates fetch_all_customers to Customer class" do
      expect(ActiveAccountingIntegration::Quickbooks::Customer).to(receive(:fetch_all)
        .with(connection))

      connection.fetch_all_customers
    end
  end

  describe "invoice methods" do
    it "delegates fetch_invoice_by_id to Invoice class" do
      expect(ActiveAccountingIntegration::Quickbooks::Invoice).to(receive(:fetch_by_id)
        .with("123", connection))

      connection.fetch_invoice_by_id("123")
    end

    it "delegates fetch_all_invoices to Invoice class" do
      expect(ActiveAccountingIntegration::Quickbooks::Invoice).to(receive(:fetch_all)
        .with(connection))

      connection.fetch_all_invoices
    end
  end
end
