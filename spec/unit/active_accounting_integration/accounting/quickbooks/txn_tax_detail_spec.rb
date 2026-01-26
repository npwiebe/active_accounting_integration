# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::TxnTaxDetail) do
  describe "attributes" do
    let(:txn_tax_detail) do
      described_class.new(
        txn_tax_code_ref: ActiveAccountingIntegration::Quickbooks::BaseReference.new(value: "TAX", name: "Sales Tax"),
        total_tax: 50.00,
        tax_line: [{ "TaxLineDetail" => { "TaxPercent" => 10 } }],
      )
    end

    it "has txn_tax_code_ref attribute" do
      expect(txn_tax_detail.txn_tax_code_ref).to(be_a(ActiveAccountingIntegration::Quickbooks::BaseReference))
      expect(txn_tax_detail.txn_tax_code_ref.value).to(eq("TAX"))
      expect(txn_tax_detail.txn_tax_code_ref.name).to(eq("Sales Tax"))
    end

    it "has total_tax attribute" do
      expect(txn_tax_detail.total_tax).to(eq(50.00))
    end

    it "has tax_line attribute" do
      expect(txn_tax_detail.tax_line).to(eq([{ "TaxLineDetail" => { "TaxPercent" => 10 } }]))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "TxnTaxCodeRef" => { "value" => "VAT", "name" => "Value Added Tax" },
        "TotalTax" => 75.00,
        "TaxLine" => [{ "TaxLineDetail" => { "TaxPercent" => 15 } }],
      }.to_json
    end

    it "deserializes from JSON" do
      txn_tax_detail = described_class.from_json(json_data)
      expect(txn_tax_detail.txn_tax_code_ref).to(be_a(ActiveAccountingIntegration::Quickbooks::BaseReference))
      expect(txn_tax_detail.txn_tax_code_ref.value).to(eq("VAT"))
      expect(txn_tax_detail.txn_tax_code_ref.name).to(eq("Value Added Tax"))
      expect(txn_tax_detail.total_tax).to(eq(75.00))
      expect(txn_tax_detail.tax_line).to(eq([{ "TaxLineDetail" => { "TaxPercent" => 15 } }]))
    end

    it "serializes to JSON" do
      txn_tax_detail = described_class.new(
        txn_tax_code_ref: ActiveAccountingIntegration::Quickbooks::BaseReference.new(value: "GST", name: "Goods and Services Tax"),
        total_tax: 100.00,
        tax_line: [{ "TaxLineDetail" => { "TaxPercent" => 20 } }],
      )
      json = JSON.parse(txn_tax_detail.to_json)
      expect(json["TxnTaxCodeRef"]["value"]).to(eq("GST"))
      expect(json["TxnTaxCodeRef"]["name"]).to(eq("Goods and Services Tax"))
      expect(json["TotalTax"]).to(eq(100.00))
      expect(json["TaxLine"]).to(eq([{ "TaxLineDetail" => { "TaxPercent" => 20 } }]))
    end
  end
end
