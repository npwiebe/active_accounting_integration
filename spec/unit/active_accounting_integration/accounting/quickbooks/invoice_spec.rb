# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::Invoice) do
  let(:connection) do
    instance_double(
      ActiveAccountingIntegration::Quickbooks::Connection,
      realm_id: "123456789",
      is_a?: true,
    )
  end

  let(:invoice_data) { load_quickbooks_fixture("invoice") }
  let(:invoices_data) { load_quickbooks_fixture("invoices") }
  let(:response) { instance_double("HTTP::Response", body: invoice_data, success?: true) }
  let(:query_response) { instance_double("HTTP::Response", body: invoices_data, success?: true) }

  subject(:invoice) { ActiveAccountingIntegration::Quickbooks::Response.from_json(invoice_data).invoice }

  describe "attributes" do
    it "reads attributes from JSON response" do
      expect(invoice.id).to(eq("123"))
      expect(invoice.doc_number).to(eq("INV-001"))
      expect(invoice.customer_ref.value).to(eq("456"))
      expect(invoice.total).to(eq(1000.00))
      expect(invoice.balance).to(eq(1000.00))
    end

    it "allows setting attributes after initialization" do
      invoice.doc_number = "INV-002"
      invoice.total = 2000.00
      expect(invoice.doc_number).to(eq("INV-002"))
      expect(invoice.total).to(eq(2000.00))
    end
  end

  describe "#save" do
    before do
      allow(invoice).to(receive(:connection).and_return(connection))
      allow(invoice).to(receive(:valid?).and_return(true))
      allow(invoice).to(receive(:push_to_source).and_return(true))
    end

    it "returns true when save is successful" do
      expect(invoice.save).to(be(true))
    end

    it "returns false when validation fails" do
      allow(invoice).to(receive(:valid?).and_return(false))
      expect(invoice.save).to(be(false))
    end

    it "returns false when push_to_source fails" do
      allow(invoice).to(receive(:push_to_source).and_return(false))
      expect(invoice.save).to(be(false))
    end
  end

  describe "#update" do
    let(:update_attributes) { { doc_number: "INV-004", total: 4000.00 } }

    before do
      allow(invoice).to(receive(:save).and_return(true))
    end

    it "assigns attributes and saves" do
      expect(invoice).to(receive(:assign_attributes).with(update_attributes))
      expect(invoice).to(receive(:save))

      invoice.update(update_attributes)
    end
  end

  describe ".create" do
    let(:create_attributes) { { doc_number: "INV-005", total: 5000.00 } }
    let(:new_invoice) { described_class.new(create_attributes) }

    before do
      allow(described_class).to(receive(:new).and_return(new_invoice))
      allow(new_invoice).to(receive(:valid?).and_return(true))
      allow(new_invoice).to(receive(:save).and_return(true))
    end

    it "creates a new invoice with attributes" do
      expect(described_class).to(receive(:new).with(create_attributes))
      described_class.create(create_attributes)
    end

    it "returns the invoice when creation is successful" do
      result = described_class.create(create_attributes)
      expect(result).to(eq(new_invoice))
    end

    it "returns the invoice even when validation fails" do
      allow(new_invoice).to(receive(:valid?).and_return(false))
      result = described_class.create(create_attributes)
      expect(result).to(eq(new_invoice))
    end
  end

  describe ".fetch_by_id" do
    context "with valid parameters" do
      before do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/invoice/123")
          .and_return(response))
      end

      it "fetches an invoice by ID" do
        invoice = described_class.fetch_by_id("123", connection)

        expect(invoice).to(be_a(described_class))
        expect(invoice.id).to(eq("123"))
        expect(invoice.doc_number).to(eq("INV-001"))
        expect(invoice.total).to(eq(1000.00))
        expect(invoice.balance).to(eq(1000.00))
      end

      it "sets persisted to true" do
        invoice = described_class.fetch_by_id("123", connection)
        expect(invoice.persisted?).to(be(true))
      end

      it "sets connection" do
        invoice = described_class.fetch_by_id("123", connection)
        expect(invoice.connection).to(eq(connection))
      end

      it "handles missing invoice data" do
        empty_response = instance_double("HTTP::Response", body: "{}")
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/invoice/123")
          .and_return(empty_response))

        expect(described_class.fetch_by_id("123", connection)).to(be_nil)
      end
    end
  end

  describe ".fetch_all" do
    context "with valid connection" do
      before do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Invoice")
          .and_return(query_response))
      end

      it "fetches all invoices" do
        invoices = described_class.fetch_all(connection)

        expect(invoices).to(be_an(Array))
        expect(invoices.length).to(eq(2))
        expect(invoices.first).to(be_a(described_class))
        expect(invoices.first.id).to(eq("123"))
        expect(invoices.first.doc_number).to(eq("INV-001"))
        expect(invoices.last.id).to(eq("124"))
        expect(invoices.last.doc_number).to(eq("INV-002"))
      end

      it "sets persisted to true for all invoices" do
        invoices = described_class.fetch_all(connection)
        invoices.each do |invoice|
          expect(invoice.persisted?).to(be(true))
        end
      end

      it "sets connection for all invoices" do
        invoices = described_class.fetch_all(connection)
        invoices.each do |invoice|
          expect(invoice.connection).to(eq(connection))
        end
      end

      it "handles empty invoice list" do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Invoice")
          .and_return(instance_double("HTTP::Response", body: load_quickbooks_fixture("empty_invoices"))))

        invoices = described_class.fetch_all(connection)
        expect(invoices).to(eq([]))
      end

      it "handles missing response data" do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Invoice")
          .and_return(instance_double("HTTP::Response", body: "{}", success?: true)))

        invoices = described_class.fetch_all(connection)
        expect(invoices).to(eq([]))
      end
    end
  end

  describe "#save" do
    before do
      allow(invoice).to(receive(:connection).and_return(connection))
      allow(connection).to(receive(:realm_id).and_return("123456789"))
    end

    it "returns true when save is successful" do
      response_obj = double(success?: true, body: { "Invoice" => { "SyncToken" => 10 } }.to_json)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      expect(invoice.save).to(be(true))
      expect(invoice.persisted?).to(be(true))
      expect(invoice.sync_token).to(eq(10))
    end

    it "returns false when save fails" do
      response_obj = double(success?: false)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      expect(invoice.save).to(be(false))
      expect(invoice.persisted?).to(be_nil)
    end

    it "updates sync token on successful save" do
      response_obj = double(success?: true, body: { "Invoice" => { "SyncToken" => 5 } }.to_json)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      invoice.save
      expect(invoice.sync_token).to(eq(5))
    end

    it "sends correct JSON structure to API" do
      invoice.doc_number = "INV-001"
      invoice.total = 1000.00

      expected_json = invoice.to_json
      expect(expected_json).to(include("DocNumber"))
      expect(expected_json).to(include("TotalAmt"))

      allow(connection).to(receive(:request)) do |method, url, options|
        expect(method).to(eq(:post))
        expect(url).to(include("/v3/company/123456789/invoice/"))
        expect(options[:body]).to(eq(expected_json))
        response_obj = double(success?: true, body: { "Invoice" => { "SyncToken" => "1" } }.to_json)
        double(response: response_obj)
      end

      invoice.save
    end
  end

  describe "private methods" do
    describe "#update_sync_token" do
      let(:response_with_sync_token) do
        instance_double("HTTP::Response", body: { "Invoice" => { "SyncToken" => "5" } }.to_json)
      end

      it "updates sync token from response" do
        invoice.send(:update_sync_token, response_with_sync_token)
        expect(invoice.sync_token).to(eq(5))
      end
    end
  end
end
