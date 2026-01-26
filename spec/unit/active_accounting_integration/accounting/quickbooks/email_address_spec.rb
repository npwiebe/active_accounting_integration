# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::EmailAddress) do
  describe "attributes" do
    it "has address attribute" do
      email = described_class.new(address: "test@example.com")
      expect(email.address).to(eq("test@example.com"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      { "Address" => "user@example.com" }.to_json
    end

    it "deserializes from JSON" do
      email = described_class.from_json(json_data)
      expect(email.address).to(eq("user@example.com"))
    end

    it "serializes to JSON" do
      email = described_class.new(address: "contact@example.com")
      json = JSON.parse(email.to_json)
      expect(json["Address"]).to(eq("contact@example.com"))
    end
  end
end
