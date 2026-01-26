# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::LineItem) do
  describe "attributes" do
    let(:line_item) do
      described_class.new(
        id: "item_1",
        line_num: 1,
        description: "Product A",
        amount: 100.00,
        detail_type: "SalesItemLineDetail",
        sales_item_line_detail: { "ItemRef" => { "value" => "123" } },
        discount_line_detail: nil,
      )
    end

    it "has id attribute" do
      expect(line_item.id).to(eq("item_1"))
    end

    it "has line_num attribute" do
      expect(line_item.line_num).to(eq(1))
    end

    it "has description attribute" do
      expect(line_item.description).to(eq("Product A"))
    end

    it "has amount attribute" do
      expect(line_item.amount).to(eq(100.00))
    end

    it "has detail_type attribute" do
      expect(line_item.detail_type).to(eq("SalesItemLineDetail"))
    end

    it "has sales_item_line_detail attribute" do
      expect(line_item.sales_item_line_detail).to(eq({ "ItemRef" => { "value" => "123" } }))
    end

    it "has discount_line_detail attribute" do
      expect(line_item.discount_line_detail).to(be_nil)
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "Id" => "item_2",
        "LineNum" => 2,
        "Description" => "Service B",
        "Amount" => 200.00,
        "DetailType" => "DiscountLineDetail",
        "SalesItemLineDetail" => nil,
        "DiscountLineDetail" => { "PercentBased" => true, "DiscountPercent" => 10 },
      }.to_json
    end

    it "deserializes from JSON" do
      line_item = described_class.from_json(json_data)
      expect(line_item.id).to(eq("item_2"))
      expect(line_item.line_num).to(eq(2))
      expect(line_item.description).to(eq("Service B"))
      expect(line_item.amount).to(eq(200.00))
      expect(line_item.detail_type).to(eq("DiscountLineDetail"))
      expect(line_item.discount_line_detail).to(eq({ "PercentBased" => true, "DiscountPercent" => 10 }))
    end

    it "serializes to JSON" do
      line_item = described_class.new(
        id: "item_3",
        line_num: 3,
        description: "Product C",
        amount: 300.00,
        detail_type: "SalesItemLineDetail",
      )
      json = JSON.parse(line_item.to_json)
      expect(json["Id"]).to(eq("item_3"))
      expect(json["LineNum"]).to(eq(3))
      expect(json["Description"]).to(eq("Product C"))
      expect(json["Amount"]).to(eq(300.00))
      expect(json["DetailType"]).to(eq("SalesItemLineDetail"))
    end
  end
end
