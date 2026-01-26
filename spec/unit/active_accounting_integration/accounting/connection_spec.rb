# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Connection) do
  describe "INTEGRATIONS" do
    it "defines supported integrations" do
      expect(described_class::INTEGRATIONS).to(include(:quickbooks))
      expect(described_class::INTEGRATIONS[:quickbooks]).to(eq("ActiveAccountingIntegration::Quickbooks::Connection"))
    end
  end

  describe ".new_test_connection" do
    before do
      allow(ActiveAccountingIntegration.configuration).to(receive(:sandbox_mode).and_return(true))
    end

    it "creates a test connection for quickbooks" do
      connection = described_class.new_test_connection(:quickbooks)

      expect(connection).to(be_a(ActiveAccountingIntegration::Quickbooks::Connection))
    end

    it "uses localhost:3000 as the redirect URI" do
      expect(ActiveAccountingIntegration::Quickbooks::Connection).to(receive(:new).with("http://localhost:3000"))
      described_class.new_test_connection(:quickbooks)
    end

    it "defaults to quickbooks integration" do
      connection = described_class.new_test_connection
      expect(connection).to(be_a(ActiveAccountingIntegration::Quickbooks::Connection))
    end
  end

  describe ".new_connection" do
    context "with valid integration" do
      it "creates a quickbooks connection" do
        connection = described_class.new_connection(:quickbooks, "http://example.com/callback")

        expect(connection).to(be_a(ActiveAccountingIntegration::Quickbooks::Connection))
      end

      it "passes options to the connection constructor" do
        expect(ActiveAccountingIntegration::Quickbooks::Connection).to(receive(:new).with("http://example.com/callback", "custom_scope", "client_id", "client_secret"))
        described_class.new_connection(:quickbooks, "http://example.com/callback", "custom_scope", "client_id", "client_secret")
      end
    end

    context "with invalid integration" do
      it "raises ArgumentError for unsupported integration" do
        expect { described_class.new_connection(:unsupported) }
          .to(raise_error(ArgumentError, "Unsupported integration: unsupported"))
      end

      it "raises ArgumentError for nil integration" do
        expect { described_class.new_connection(nil) }
          .to(raise_error(ArgumentError, "Unsupported integration: "))
      end
    end

    context "with string integration name" do
      it "converts string to symbol" do
        connection = described_class.new_connection("quickbooks", "http://example.com/callback")
        expect(connection).to(be_a(ActiveAccountingIntegration::Quickbooks::Connection))
      end
    end
  end
end
