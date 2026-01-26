# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::MetaData) do
  describe "attributes" do
    it "has create_time attribute" do
      metadata = described_class.new(create_time: "2024-01-01T10:00:00Z")
      expect(metadata.create_time).to(eq("2024-01-01T10:00:00Z"))
    end

    it "has last_updated_time attribute" do
      metadata = described_class.new(last_updated_time: "2024-01-02T15:30:00Z")
      expect(metadata.last_updated_time).to(eq("2024-01-02T15:30:00Z"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "CreateTime" => "2024-01-01T10:00:00Z",
        "LastUpdatedTime" => "2024-01-02T15:30:00Z",
      }.to_json
    end

    it "deserializes from JSON" do
      metadata = described_class.from_json(json_data)
      expect(metadata.create_time).to(eq("2024-01-01T10:00:00Z"))
      expect(metadata.last_updated_time).to(eq("2024-01-02T15:30:00Z"))
    end

    it "serializes to JSON" do
      metadata = described_class.new(
        create_time: "2024-03-01T08:00:00Z",
        last_updated_time: "2024-03-05T12:00:00Z",
      )
      json = JSON.parse(metadata.to_json)
      expect(json["CreateTime"]).to(eq("2024-03-01T08:00:00Z"))
      expect(json["LastUpdatedTime"]).to(eq("2024-03-05T12:00:00Z"))
    end
  end
end
