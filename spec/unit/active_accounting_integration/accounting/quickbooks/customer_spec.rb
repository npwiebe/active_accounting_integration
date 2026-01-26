# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::Quickbooks::Customer) do
  let(:connection) do
    instance_double(
      ActiveAccountingIntegration::Quickbooks::Connection,
      realm_id: "123456789",
      is_a?: true,
    )
  end

  let(:customer_data) { load_quickbooks_fixture("customer") }
  let(:customers_data) { load_quickbooks_fixture("customers") }
  let(:response) { instance_double("HTTP::Response", body: customer_data, success?: true) }
  let(:query_response) { instance_double("HTTP::Response", body: customers_data, success?: true) }

  subject(:customer) { ActiveAccountingIntegration::Quickbooks::Response.from_json(customer_data).customer }

  describe "attributes" do
    it "reads attributes from JSON response" do
      expect(customer.id).to(eq("123"))
      expect(customer.display_name).to(eq("John Doe"))
      expect(customer.primary_email_address.address).to(eq("john@example.com"))
      expect(customer.primary_phone.free_form_number).to(eq("+1-555-123-4567"))
    end

    it "allows setting attributes after initialization" do
      customer.display_name = "Jane Doe"
      customer.primary_email_address.address = "jane@example.com"
      expect(customer.display_name).to(eq("Jane Doe"))
      expect(customer.primary_email_address.address).to(eq("jane@example.com"))
    end
  end

  describe "#save" do
    before do
      allow(customer).to(receive(:connection).and_return(connection))
      allow(customer).to(receive(:valid?).and_return(true))
      allow(customer).to(receive(:push_to_source).and_return(true))
    end

    it "returns true when save is successful" do
      expect(customer.save).to(be(true))
    end

    it "returns false when validation fails" do
      allow(customer).to(receive(:valid?).and_return(false))
      expect(customer.save).to(be(false))
    end

    it "returns false when push_to_source fails" do
      allow(customer).to(receive(:push_to_source).and_return(false))
      expect(customer.save).to(be(false))
    end
  end

  describe "#update" do
    let(:update_attributes) { { display_name: "Updated Customer", primary_email_address: { address: "updated@example.com" } } }

    before do
      allow(customer).to(receive(:save).and_return(true))
    end

    it "assigns attributes and saves" do
      expect(customer).to(receive(:assign_attributes).with(update_attributes))
      expect(customer).to(receive(:save))

      customer.update(update_attributes)
    end
  end

  describe ".create" do
    let(:create_attributes) { { display_name: "New Customer", primary_email_address: { address: "new@example.com" } } }
    let(:new_customer) { described_class.new(create_attributes) }

    before do
      allow(described_class).to(receive(:new).and_return(new_customer))
      allow(new_customer).to(receive(:valid?).and_return(true))
      allow(new_customer).to(receive(:save).and_return(true))
    end

    it "creates a new customer with attributes" do
      expect(described_class).to(receive(:new).with(create_attributes))
      described_class.create(create_attributes)
    end

    it "returns the customer when creation is successful" do
      result = described_class.create(create_attributes)
      expect(result).to(eq(new_customer))
    end

    it "returns the customer even when validation fails" do
      allow(new_customer).to(receive(:valid?).and_return(false))
      result = described_class.create(create_attributes)
      expect(result).to(eq(new_customer))
    end
  end

  describe ".fetch_by_id" do
    context "with valid parameters" do
      before do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/customer/123")
          .and_return(response))
      end

      it "fetches a customer by ID" do
        customer = described_class.fetch_by_id("123", connection)

        expect(customer).to(be_a(described_class))
        expect(customer.id).to(eq("123"))
        expect(customer.display_name).to(eq("John Doe"))
        expect(customer.primary_email_address.address).to(eq("john@example.com"))
        expect(customer.primary_phone.free_form_number).to(eq("+1-555-123-4567"))
      end

      it "sets persisted to true" do
        customer = described_class.fetch_by_id("123", connection)
        expect(customer.persisted?).to(be(true))
      end

      it "sets connection" do
        customer = described_class.fetch_by_id("123", connection)
        expect(customer.connection).to(eq(connection))
      end

      it "handles missing customer data" do
        empty_response = instance_double("HTTP::Response", body: "{}")
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/customer/123")
          .and_return(empty_response))

        expect(described_class.fetch_by_id("123", connection)).to(be_nil)
      end
    end
  end

  describe ".fetch_all" do
    context "with valid connection" do
      before do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Customer")
          .and_return(query_response))
      end

      it "fetches all customers" do
        customers = described_class.fetch_all(connection)

        expect(customers).to(be_an(Array))
        expect(customers.length).to(eq(2))
        expect(customers.first).to(be_a(described_class))
        expect(customers.first.id).to(eq("123"))
        expect(customers.first.display_name).to(eq("John Doe"))
        expect(customers.last.id).to(eq("456"))
        expect(customers.last.display_name).to(eq("Jane Smith"))
      end

      it "sets persisted to true for all customers" do
        customers = described_class.fetch_all(connection)
        customers.each do |customer|
          expect(customer.persisted?).to(be(true))
        end
      end

      it "sets connection for all customers" do
        customers = described_class.fetch_all(connection)
        customers.each do |customer|
          expect(customer.connection).to(eq(connection))
        end
      end

      it "handles empty customer list" do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Customer")
          .and_return(instance_double("HTTP::Response", body: load_quickbooks_fixture("empty_customers"))))

        customers = described_class.fetch_all(connection)
        expect(customers).to(eq([]))
      end

      it "handles missing response data" do
        allow(connection).to(receive(:request)
          .with(:get, "/v3/company/123456789/query?query=select * from Customer")
          .and_return(instance_double("HTTP::Response", body: "{}", success?: true)))

        customers = described_class.fetch_all(connection)
        expect(customers).to(eq([]))
      end
    end
  end

  describe ".customer_url_builder" do
    it "builds URL for single customer" do
      url = described_class.customer_url_builder(connection)
      expect(url).to(eq("/v3/company/123456789/customer/"))
    end

    it "builds URL with query parameters" do
      url = described_class.customer_url_builder(connection, query: "select * from Customer where DisplayName = 'John'")
      expect(url).to(eq("/v3/company/123456789/query?query=select * from Customer where DisplayName = 'John'"))
    end
  end

  describe "#save" do
    before do
      allow(customer).to(receive(:connection).and_return(connection))
      allow(connection).to(receive(:realm_id).and_return("123456789"))
    end

    it "returns true when save is successful" do
      response_obj = double(success?: true, body: { "Customer" => { "SyncToken" => 10 } }.to_json)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      expect(customer.save).to(be(true))
      expect(customer.persisted?).to(be(true))
      expect(customer.sync_token).to(eq(10))
    end

    it "returns false when save fails" do
      response_obj = double(success?: false)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      expect(customer.save).to(be(false))
      expect(customer.persisted?).to(be_nil)
    end

    it "updates sync token on successful save" do
      response_obj = double(success?: true, body: { "Customer" => { "SyncToken" => 5 } }.to_json)
      request_result = double(response: response_obj)
      allow(connection).to(receive(:request).and_return(request_result))

      customer.save
      expect(customer.sync_token).to(eq(5))
    end

    it "sends correct JSON structure to API" do
      customer.display_name = "Test Customer"

      expected_json = customer.to_json
      expect(expected_json).to(include("DisplayName"))

      allow(connection).to(receive(:request)) do |method, url, options|
        expect(method).to(eq(:post))
        expect(url).to(include("/v3/company/123456789/customer/"))
        expect(options[:body]).to(eq(expected_json))
        response_obj = double(success?: true, body: { "Customer" => { "SyncToken" => "1" } }.to_json)
        double(response: response_obj)
      end

      customer.save
    end
  end

  describe "private methods" do
    describe "#update_sync_token" do
      let(:response_with_sync_token) do
        instance_double("HTTP::Response", body: { "Customer" => { "SyncToken" => "5" } }.to_json)
      end

      it "updates sync token from response" do
        customer.send(:update_sync_token, response_with_sync_token)
        expect(customer.sync_token).to(eq(5))
      end
    end
  end
end
