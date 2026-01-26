# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::Line) do
  describe "attributes" do
    let(:line) do
      described_class.new(
        id: "line_1",
        line_num: 1,
        description: "Payment line",
        amount: 500.00,
        linked_txn: [{ "TxnId" => "txn_123" }],
      )
    end

    it "has id attribute" do
      expect(line.id).to(eq("line_1"))
    end

    it "has line_num attribute" do
      expect(line.line_num).to(eq(1))
    end

    it "has description attribute" do
      expect(line.description).to(eq("Payment line"))
    end

    it "has amount attribute" do
      expect(line.amount).to(eq(500.00))
    end

    it "has linked_txn attribute" do
      expect(line.linked_txn).to(eq([{ "TxnId" => "txn_123" }]))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "Id" => "line_2",
        "LineNum" => 2,
        "Description" => "Service charge",
        "Amount" => 250.00,
        "LinkedTxn" => [{ "TxnId" => "txn_456" }],
      }.to_json
    end

    it "deserializes from JSON" do
      line = described_class.from_json(json_data)
      expect(line.id).to(eq("line_2"))
      expect(line.line_num).to(eq(2))
      expect(line.description).to(eq("Service charge"))
      expect(line.amount).to(eq(250.00))
      expect(line.linked_txn).to(eq([{ "TxnId" => "txn_456" }]))
    end

    it "serializes to JSON" do
      line = described_class.new(
        id: "line_3",
        line_num: 3,
        description: "Discount",
        amount: -50.00,
      )
      json = JSON.parse(line.to_json)
      expect(json["Id"]).to(eq("line_3"))
      expect(json["LineNum"]).to(eq(3))
      expect(json["Description"]).to(eq("Discount"))
      expect(json["Amount"]).to(eq(-50.00))
    end
  end
end
