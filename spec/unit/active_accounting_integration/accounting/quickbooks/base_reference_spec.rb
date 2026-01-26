# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::BaseReference) do
  describe "attributes" do
    it "has value attribute" do
      reference = described_class.new(value: "123")
      expect(reference.value).to(eq("123"))
    end

    it "has name attribute" do
      reference = described_class.new(name: "Test Name")
      expect(reference.name).to(eq("Test Name"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "value" => "456",
        "name" => "Customer Reference",
      }.to_json
    end

    it "deserializes from JSON" do
      reference = described_class.from_json(json_data)
      expect(reference.value).to(eq("456"))
      expect(reference.name).to(eq("Customer Reference"))
    end

    it "serializes to JSON" do
      reference = described_class.new(value: "789", name: "Invoice Reference")
      json = JSON.parse(reference.to_json)
      expect(json["value"]).to(eq("789"))
      expect(json["name"]).to(eq("Invoice Reference"))
    end
  end
end
