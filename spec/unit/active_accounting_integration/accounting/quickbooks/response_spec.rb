# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::Response) do
  describe "attributes" do
    it "has query_response attribute" do
      response = described_class.new(query_response: nil)
      expect(response).to(respond_to(:query_response))
    end

    it "has payment attribute" do
      response = described_class.new(payment: nil)
      expect(response).to(respond_to(:payment))
    end

    it "has customer attribute" do
      response = described_class.new(customer: nil)
      expect(response).to(respond_to(:customer))
    end

    it "has invoice attribute" do
      response = described_class.new(invoice: nil)
      expect(response).to(respond_to(:invoice))
    end
  end

  describe "JSON mapping" do
    context "with query response" do
      let(:json_data) do
        {
          "QueryResponse" => {
            "Payment" => [{ "Id" => "pay_1", "TotalAmt" => 100.00 }],
            "Customer" => [],
            "Invoice" => [],
          },
        }.to_json
      end

      it "deserializes query response from JSON" do
        response = described_class.from_json(json_data)
        expect(response.query_response).to(be_a(ActiveAccountingIntegration::Quickbooks::QueryResponse))
        expect(response.query_response.payments.length).to(eq(1))
        expect(response.query_response.payments.first.id).to(eq("pay_1"))
      end
    end

    context "with individual entities" do
      let(:json_data) do
        {
          "Payment" => { "Id" => "pay_2", "TotalAmt" => 200.00 },
          "Customer" => { "Id" => "cust_1", "DisplayName" => "Test Customer" },
          "Invoice" => { "Id" => "inv_1", "TotalAmt" => 500.00 },
        }.to_json
      end

      it "deserializes individual entities from JSON" do
        response = described_class.from_json(json_data)

        expect(response.payment).to(be_a(ActiveAccountingIntegration::Quickbooks::Payment))
        expect(response.payment.id).to(eq("pay_2"))
        expect(response.payment.total).to(eq(200.00))

        expect(response.customer).to(be_a(ActiveAccountingIntegration::Quickbooks::Customer))
        expect(response.customer.id).to(eq("cust_1"))
        expect(response.customer.display_name).to(eq("Test Customer"))

        expect(response.invoice).to(be_a(ActiveAccountingIntegration::Quickbooks::Invoice))
        expect(response.invoice.id).to(eq("inv_1"))
        expect(response.invoice.total).to(eq(500.00))
      end
    end

    it "serializes to JSON" do
      payment = ActiveAccountingIntegration::Quickbooks::Payment.new
      payment.id = "pay_3"
      payment.total = 300.00

      customer = ActiveAccountingIntegration::Quickbooks::Customer.new
      customer.id = "cust_2"
      customer.display_name = "Customer 2"

      response = described_class.new(
        payment: payment,
        customer: customer,
      )

      json = JSON.parse(response.to_json)
      expect(json).to(have_key("Payment"))
      expect(json).to(have_key("Customer"))
    end
  end
end
