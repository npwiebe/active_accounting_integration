# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::PhysicalAddress) do
  describe "attributes" do
    let(:address) do
      described_class.new(
        id: "addr_1",
        line1: "123 Main St",
        line2: "Apt 4",
        line3: "Building A",
        line4: "Floor 2",
        line5: "Suite 100",
        city: "New York",
        country: "USA",
        country_sub_division_code: "NY",
        postal_code: "10001",
        lat: "40.7128",
        long: "-74.0060",
      )
    end

    it "has all address line attributes" do
      expect(address.id).to(eq("addr_1"))
      expect(address.line1).to(eq("123 Main St"))
      expect(address.line2).to(eq("Apt 4"))
      expect(address.line3).to(eq("Building A"))
      expect(address.line4).to(eq("Floor 2"))
      expect(address.line5).to(eq("Suite 100"))
    end

    it "has location attributes" do
      expect(address.city).to(eq("New York"))
      expect(address.country).to(eq("USA"))
      expect(address.country_sub_division_code).to(eq("NY"))
      expect(address.postal_code).to(eq("10001"))
    end

    it "has coordinate attributes" do
      expect(address.lat).to(eq("40.7128"))
      expect(address.long).to(eq("-74.0060"))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "Id" => "addr_2",
        "Line1" => "456 Oak Ave",
        "Line2" => "Unit 5",
        "City" => "Los Angeles",
        "Country" => "USA",
        "CountrySubDivisionCode" => "CA",
        "PostalCode" => "90001",
        "Lat" => "34.0522",
        "Long" => "-118.2437",
      }.to_json
    end

    it "deserializes from JSON" do
      address = described_class.from_json(json_data)
      expect(address.id).to(eq("addr_2"))
      expect(address.line1).to(eq("456 Oak Ave"))
      expect(address.line2).to(eq("Unit 5"))
      expect(address.city).to(eq("Los Angeles"))
      expect(address.country).to(eq("USA"))
      expect(address.country_sub_division_code).to(eq("CA"))
      expect(address.postal_code).to(eq("90001"))
      expect(address.lat).to(eq("34.0522"))
      expect(address.long).to(eq("-118.2437"))
    end

    it "serializes to JSON" do
      address = described_class.new(
        id: "addr_3",
        line1: "789 Pine Rd",
        city: "Chicago",
        postal_code: "60601",
      )
      json = JSON.parse(address.to_json)
      expect(json["Id"]).to(eq("addr_3"))
      expect(json["Line1"]).to(eq("789 Pine Rd"))
      expect(json["City"]).to(eq("Chicago"))
      expect(json["PostalCode"]).to(eq("60601"))
    end
  end
end
