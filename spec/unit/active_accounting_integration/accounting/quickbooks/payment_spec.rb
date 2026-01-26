# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::Payment) do
  let(:connection) do
    instance_double(
      ActiveAccountingIntegration::Quickbooks::Connection,
      realm_id: "123456789",
      is_a?: true,
    )
  end

  let(:payment_data) { load_quickbooks_fixture("payment") }
  let(:payments_data) { load_quickbooks_fixture("payments") }
  let(:response) { instance_double("HTTP::Response", body: payment_data, success?: true) }
  let(:query_response) { instance_double("HTTP::Response", body: payments_data, success?: true) }

  subject(:payment) { ActiveAccountingIntegration::Quickbooks::Response.from_json(payment_data).payment }

  describe "attributes" do
    it "reads attributes from JSON response" do
      expect(payment.id).to(eq("123"))
      expect(payment.total).to(eq(500.00))
      expect(payment.customer_ref.value).to(eq("456"))
      expect(payment.customer_ref.name).to(eq("John Doe"))
    end

    it "allows setting attributes after initialization" do
      payment.total = 600.00
      payment.payment_ref_number = "CHK-12345"
      expect(payment.total).to(eq(600.00))
      expect(payment.payment_ref_number).to(eq("CHK-12345"))
    end
  end

  describe "#save" do
    before do
      allow(payment).to(receive(:connection).and_return(connection))
      allow(payment).to(receive(:valid?).and_return(true))
      allow(payment).to(receive(:push_to_source).and_return(true))
    end

    it "returns true when save is successful" do
      expect(payment.save).to(be(true))
    end

    it "returns false when validation fails" do
      allow(payment).to(receive(:valid?).and_return(false))
      expect(payment.save).to(be(false))
    end

    it "returns false when push_to_source fails" do
      allow(payment).to(receive(:push_to_source).and_return(false))
      expect(payment.save).to(be(false))
    end
  end

  describe "#update" do
    let(:update_attributes) { { total: 700.00, payment_ref_number: "CHK-99999" } }

    before do
      allow(payment).to(receive(:save).and_return(true))
    end

    it "assigns attributes and saves" do
      expect(payment).to(receive(:assign_attributes).with(update_attributes))
      expect(payment).to(receive(:save))

      payment.update(update_attributes)
    end
  end

  describe ".create" do
    let(:create_attributes) { { total: 800.00, payment_ref_number: "CHK-88888" } }
    let(:new_payment) { described_class.new(create_attributes) }

    before do
      allow(described_class).to(receive(:new).and_return(new_payment))
      allow(new_payment).to(receive(:valid?).and_return(true))
      allow(new_payment).to(receive(:save).and_return(true))
    end

    it "creates a new payment with attributes" do
      expect(described_class).to(receive(:new).with(create_attributes))
      described_class.create(create_attributes)
    end

    it "returns the payment when creation is successful" do
      result = described_class.create(create_attributes)
      expect(result).to(eq(new_payment))
    end

    it "returns the payment even when validation fails" do
      allow(new_payment).to(receive(:valid?).and_return(false))
      result = described_class.create(create_attributes)
      expect(result).to(eq(new_payment))
    end
  end

  describe ".fetch_by_id" do
    context "with valid parameters" do
      before do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/payment/123")
          .and_return(response))
      end

      it "fetches a payment by ID" do
        payment = described_class.fetch_by_id("123", connection)

        expect(payment).to(be_a(described_class))
        expect(payment.id).to(eq("123"))
        expect(payment.total).to(eq(500.00))
        expect(payment.customer_ref.value).to(eq("456"))
      end

      it "sets persisted to true" do
        payment = described_class.fetch_by_id("123", connection)
        expect(payment.persisted?).to(be(true))
      end

      it "sets connection" do
        payment = described_class.fetch_by_id("123", connection)
        expect(payment.connection).to(eq(connection))
      end

      it "handles missing payment data" do
        empty_response = instance_double("HTTP::Response", body: "{}")
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/payment/123")
          .and_return(empty_response))

        expect(described_class.fetch_by_id("123", connection)).to(be_nil)
      end
    end
  end

  describe ".fetch_all" do
    context "with valid connection" do
      before do
        request_result = double(response: query_response)
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Payment")
          .and_return(request_result))
      end

      it "fetches all payments" do
        payments = described_class.fetch_all(connection)

        expect(payments).to(be_an(Array))
        expect(payments.length).to(eq(2))
        expect(payments.first).to(be_a(described_class))
        expect(payments.first.id).to(eq("123"))
        expect(payments.last.id).to(eq("456"))
      end

      it "sets persisted to true for all payments" do
        payments = described_class.fetch_all(connection)
        payments.each do |payment|
          expect(payment.persisted?).to(be(true))
        end
      end

      it "sets connection for all payments" do
        payments = described_class.fetch_all(connection)
        payments.each do |payment|
          expect(payment.connection).to(eq(connection))
        end
      end

      it "handles empty payment list" do
        empty_response = instance_double("HTTP::Response", body: load_quickbooks_fixture("empty_payments"))
        request_result = double(response: empty_response)
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Payment")
          .and_return(request_result))

        payments = described_class.fetch_all(connection)
        expect(payments).to(eq([]))
      end

      it "handles missing response data" do
        empty_response = instance_double("HTTP::Response", body: "{}", success?: true)
        request_result = double(response: empty_response)
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Payment")
          .and_return(request_result))

        payments = described_class.fetch_all(connection)
        expect(payments).to(eq([]))
      end
    end
  end

  describe ".payment_url_builder" do
    it "builds URL for single payment" do
      url = described_class.payment_url_builder(connection)
      expect(url).to(eq("/v3/company/123456789/payment/"))
    end

    it "builds URL with query parameters" do
      url = described_class.payment_url_builder(connection, query: "select * from Payment where TotalAmt > 500")
      expect(url).to(eq("/v3/company/123456789/query?query=select * from Payment where TotalAmt > 500"))
    end
  end

  describe "#save" do
    before do
      allow(payment).to(receive(:connection).and_return(connection))
      allow(connection).to(receive(:realm_id).and_return("123456789"))
    end

    it "returns true when save is successful" do
      response_obj = double(success?: true, body: { "Payment" => { "SyncToken" => 10 } }.to_json)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      expect(payment.save).to(be(true))
      expect(payment.persisted?).to(be(true))
      expect(payment.sync_token).to(eq(10))
    end

    it "returns false when save fails" do
      response_obj = double(success?: false)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      expect(payment.save).to(be(false))
      expect(payment.persisted?).to(be_nil)
    end

    it "updates sync token on successful save" do
      response_obj = double(success?: true, body: { "Payment" => { "SyncToken" => 5 } }.to_json)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      payment.save
      expect(payment.sync_token).to(eq(5))
    end

    it "sends correct JSON structure to API" do
      payment.total = 1000.00

      expected_json = payment.to_json
      expect(expected_json).to(include("TotalAmt"))

      allow(connection).to(receive(:request)) do |method, url, options|
        expect(method).to(eq(:post))
        expect(url).to(include("/v3/company/123456789/payment/"))
        expect(options[:body]).to(eq(expected_json))
        response_obj = double(success?: true, body: { "Payment" => { "SyncToken" => "1" } }.to_json)
        double(response: response_obj)
      end

      payment.save
    end
  end

  describe "private methods" do
    describe "#update_sync_token" do
      let(:response_with_sync_token) do
        instance_double("HTTP::Response", body: { "Payment" => { "SyncToken" => "5" } }.to_json)
      end

      it "updates sync token from response" do
        payment.send(:update_sync_token, response_with_sync_token)
        expect(payment.sync_token).to(eq(5))
      end
    end
  end
end
