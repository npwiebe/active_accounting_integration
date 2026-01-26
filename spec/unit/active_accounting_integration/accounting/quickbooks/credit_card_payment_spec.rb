# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::CreditCardPayment) do
  describe "attributes" do
    let(:credit_card_payment) do
      described_class.new(
        credit_charge_info: { "card_type" => "Visa" },
        credit_charge_response: { "status" => "Completed" },
      )
    end

    it "has credit_charge_info attribute" do
      expect(credit_card_payment.credit_charge_info).to(eq({ "card_type" => "Visa" }))
    end

    it "has credit_charge_response attribute" do
      expect(credit_card_payment.credit_charge_response).to(eq({ "status" => "Completed" }))
    end
  end

  describe "JSON mapping" do
    let(:json_data) do
      {
        "CreditChargeInfo" => { "card_type" => "MasterCard", "last_four" => "1234" },
        "CreditChargeResponse" => { "status" => "Approved", "txn_id" => "txn_123" },
      }.to_json
    end

    it "deserializes from JSON" do
      credit_card_payment = described_class.from_json(json_data)
      expect(credit_card_payment.credit_charge_info["card_type"]).to(eq("MasterCard"))
      expect(credit_card_payment.credit_charge_info["last_four"]).to(eq("1234"))
      expect(credit_card_payment.credit_charge_response["status"]).to(eq("Approved"))
      expect(credit_card_payment.credit_charge_response["txn_id"]).to(eq("txn_123"))
    end

    it "serializes to JSON" do
      credit_card_payment = described_class.new(
        credit_charge_info: { "card_type" => "Amex" },
        credit_charge_response: { "status" => "Pending" },
      )
      json = JSON.parse(credit_card_payment.to_json)
      expect(json["CreditChargeInfo"]["card_type"]).to(eq("Amex"))
      expect(json["CreditChargeResponse"]["status"]).to(eq("Pending"))
    end
  end
end
