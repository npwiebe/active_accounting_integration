# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::LinkedTransaction) do
  describe "attributes" do
    let(:linked_txn) do
      described_class.new(
        txn_id: "txn_123",
        txn_type: "Invoice",
        txn_line_id: "line_456",
      )
    end

    it "has txn_id attribute" do
      expect(linked_txn.txn_id).to(eq("txn_123"))
    end

    it "has txn_type attribute" do
      expect(linked_txn.txn_type).to(eq("Invoice"))
    end

    it "has txn_line_id attribute" do
      expect(linked_txn.txn_line_id).to(eq("line_456"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "TxnId" => "txn_789",
        "TxnType" => "Payment",
        "TxnLineId" => "line_999",
      }.to_json
    end

    it "deserializes from JSON" do
      linked_txn = described_class.from_json(json_data)
      expect(linked_txn.txn_id).to(eq("txn_789"))
      expect(linked_txn.txn_type).to(eq("Payment"))
      expect(linked_txn.txn_line_id).to(eq("line_999"))
    end

    it "serializes to JSON" do
      linked_txn = described_class.new(
        txn_id: "txn_111",
        txn_type: "CreditMemo",
        txn_line_id: "line_222",
      )
      json = JSON.parse(linked_txn.to_json)
      expect(json["TxnId"]).to(eq("txn_111"))
      expect(json["TxnType"]).to(eq("CreditMemo"))
      expect(json["TxnLineId"]).to(eq("line_222"))
    end
  end
end
