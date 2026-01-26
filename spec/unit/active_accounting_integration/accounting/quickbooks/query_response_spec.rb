# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::QueryResponse) do
  describe "attributes" do
    it "has payments collection attribute" do
      query_response = described_class.new(payments: [])
      expect(query_response.payments).to(eq([]))
    end

    it "has customers collection attribute" do
      query_response = described_class.new(customers: [])
      expect(query_response.customers).to(eq([]))
    end

    it "has invoices collection attribute" do
      query_response = described_class.new(invoices: [])
      expect(query_response.invoices).to(eq([]))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "Payment" => [
          { "Id" => "pay_1", "TotalAmt" => 100.00 },
          { "Id" => "pay_2", "TotalAmt" => 200.00 },
        ],
        "Customer" => [
          { "Id" => "cust_1", "DisplayName" => "Customer 1" },
        ],
        "Invoice" => [
          { "Id" => "inv_1", "TotalAmt" => 500.00 },
        ],
      }.to_json
    end

    it "deserializes from JSON with collections" do
      query_response = described_class.from_json(json_data)

      expect(query_response.payments).to(be_an(Array))
      expect(query_response.payments.length).to(eq(2))
      expect(query_response.payments.first).to(be_a(ActiveAccountingIntegration::Quickbooks::Payment))
      expect(query_response.payments.first.id).to(eq("pay_1"))

      expect(query_response.customers).to(be_an(Array))
      expect(query_response.customers.length).to(eq(1))
      expect(query_response.customers.first).to(be_a(ActiveAccountingIntegration::Quickbooks::Customer))
      expect(query_response.customers.first.id).to(eq("cust_1"))

      expect(query_response.invoices).to(be_an(Array))
      expect(query_response.invoices.length).to(eq(1))
      expect(query_response.invoices.first).to(be_a(ActiveAccountingIntegration::Quickbooks::Invoice))
      expect(query_response.invoices.first.id).to(eq("inv_1"))
    end

    it "serializes to JSON" do
      payment = ActiveAccountingIntegration::Quickbooks::Payment.new(id: "pay_3", total: 300.00)
      customer = ActiveAccountingIntegration::Quickbooks::Customer.new(id: "cust_2", display_name: "Customer 2")

      query_response = described_class.new(
        payments: [payment],
        customers: [customer],
        invoices: [],
      )

      json = JSON.parse(query_response.to_json)
      expect(json["Payment"]).to(be_an(Array))
      expect(json["Payment"].length).to(eq(1))
      expect(json["Customer"]).to(be_an(Array))
      expect(json["Customer"].length).to(eq(1))
    end
  end
end
