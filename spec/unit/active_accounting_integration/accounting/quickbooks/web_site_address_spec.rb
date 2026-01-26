# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::WebSiteAddress) do
  describe "attributes" do
    it "has uri attribute" do
      website = described_class.new(uri: "https://example.com")
      expect(website.uri).to(eq("https://example.com"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      { "URI" => "https://company.com" }.to_json
    end

    it "deserializes from JSON" do
      website = described_class.from_json(json_data)
      expect(website.uri).to(eq("https://company.com"))
    end

    it "serializes to JSON" do
      website = described_class.new(uri: "https://mysite.com")
      json = JSON.parse(website.to_json)
      expect(json["URI"]).to(eq("https://mysite.com"))
    end
  end
end
