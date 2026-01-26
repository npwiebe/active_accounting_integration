# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::DeliveryInfo) do
  describe "attributes" do
    let(:delivery_info) do
      described_class.new(
        delivery_type: "Email",
        delivery_time: "2024-01-15T10:00:00Z",
      )
    end

    it "has delivery_type attribute" do
      expect(delivery_info.delivery_type).to(eq("Email"))
    end

    it "has delivery_time attribute" do
      expect(delivery_info.delivery_time).to(eq("2024-01-15T10:00:00Z"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "DeliveryType" => "Print",
        "DeliveryTime" => "2024-02-20T14:30:00Z",
      }.to_json
    end

    it "deserializes from JSON" do
      delivery_info = described_class.from_json(json_data)
      expect(delivery_info.delivery_type).to(eq("Print"))
      expect(delivery_info.delivery_time).to(eq("2024-02-20T14:30:00Z"))
    end

    it "serializes to JSON" do
      delivery_info = described_class.new(
        delivery_type: "Mail",
        delivery_time: "2024-03-10T09:00:00Z",
      )
      json = JSON.parse(delivery_info.to_json)
      expect(json["DeliveryType"]).to(eq("Mail"))
      expect(json["DeliveryTime"]).to(eq("2024-03-10T09:00:00Z"))
    end
  end
end
