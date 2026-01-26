# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::CustomField) do
  describe "attributes" do
    let(:custom_field) do
      described_class.new(
        definition_id: "def_123",
        name: "CustomField1",
        type: "StringType",
        string_value: "Sample Value",
      )
    end

    it "has definition_id attribute" do
      expect(custom_field.definition_id).to(eq("def_123"))
    end

    it "has name attribute" do
      expect(custom_field.name).to(eq("CustomField1"))
    end

    it "has type attribute" do
      expect(custom_field.type).to(eq("StringType"))
    end

    it "has string_value attribute" do
      expect(custom_field.string_value).to(eq("Sample Value"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "DefinitionId" => "def_456",
        "Name" => "CustomField2",
        "Type" => "BooleanType",
        "StringValue" => "true",
      }.to_json
    end

    it "deserializes from JSON" do
      custom_field = described_class.from_json(json_data)
      expect(custom_field.definition_id).to(eq("def_456"))
      expect(custom_field.name).to(eq("CustomField2"))
      expect(custom_field.type).to(eq("BooleanType"))
      expect(custom_field.string_value).to(eq("true"))
    end

    it "serializes to JSON" do
      custom_field = described_class.new(
        definition_id: "def_789",
        name: "CustomField3",
        type: "NumberType",
        string_value: "100",
      )
      json = JSON.parse(custom_field.to_json)
      expect(json["DefinitionId"]).to(eq("def_789"))
      expect(json["Name"]).to(eq("CustomField3"))
      expect(json["Type"]).to(eq("NumberType"))
      expect(json["StringValue"]).to(eq("100"))
    end
  end
end
