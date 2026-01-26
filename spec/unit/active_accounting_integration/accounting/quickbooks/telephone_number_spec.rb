# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::TelephoneNumber) do
  describe "attributes" do
    it "has free_form_number attribute" do
      phone = described_class.new(free_form_number: "+1-555-1234")
      expect(phone.free_form_number).to(eq("+1-555-1234"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      { "FreeFormNumber" => "+1-555-5678" }.to_json
    end

    it "deserializes from JSON" do
      phone = described_class.from_json(json_data)
      expect(phone.free_form_number).to(eq("+1-555-5678"))
    end

    it "serializes to JSON" do
      phone = described_class.new(free_form_number: "+1-555-9999")
      json = JSON.parse(phone.to_json)
      expect(json["FreeFormNumber"]).to(eq("+1-555-9999"))
    end
  end
end
