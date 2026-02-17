# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::ActiveRecord::Mountable) do
  let(:mapper_to) do
    proc do |_accounting_model|
      { given_name: first_name, family_name: last_name, display_name: name }
    end
  end

  let(:mapper_from) do
    proc do |accounting_model|
      {
        first_name: accounting_model.given_name,
        last_name: accounting_model.family_name,
        name: accounting_model.display_name,
        email: accounting_model.email,
      }
    end
  end

  let(:test_class) do
    Class.new do
      include ActiveAccountingIntegration::ActiveRecord::Mountable

      attr_accessor :name, :email, :first_name, :last_name, :quickbooks_customer_id

      def assign_attributes(attrs)
        attrs.each { |k, v| public_send("#{k}=", v) }
      end

      def save
        true
      end

      def quickbooks_customer_connection
        nil
      end
    end
  end

  let(:mock_connection) { double("connection") }
  let(:mock_accounting_model) do
    double("accounting_model").tap do |model|
      allow(model).to(receive(:id).and_return("123"))
      allow(model).to(receive(:given_name).and_return("John"))
      allow(model).to(receive(:family_name).and_return("Doe"))
      allow(model).to(receive(:display_name).and_return("John Doe"))
      allow(model).to(receive(:email).and_return("john@example.com"))
      allow(model).to(receive(:respond_to?).and_return(true))
      allow(model).to(receive(:save).and_return(true))
      allow(model).to(receive(:given_name=))
      allow(model).to(receive(:family_name=))
      allow(model).to(receive(:display_name=))
    end
  end

  let(:mock_accounting_class) do
    double("accounting_class").tap do |klass|
      allow(klass).to(receive(:fetch_by_id).and_return(mock_accounting_model))
      allow(klass).to(receive(:new).and_return(mock_accounting_model))
    end
  end

  describe ".mounts_accounting_model" do
    it "stores configuration in class attribute" do
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        mapper_to: mapper_to,
        mapper_from: mapper_from,
      )

      config = test_class._mounted_accounting_models[:quickbooks_customer]
      expect(config[:class_name]).to(eq("TestAccountingModel"))
      expect(config[:external_id_column]).to(eq(:quickbooks_customer_id))
      expect(config[:mapper_to]).to(eq(mapper_to))
      expect(config[:mapper_from]).to(eq(mapper_from))
    end

    it "allows custom connection method" do
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        connection_method: :custom_connection,
        mapper_to: mapper_to,
        mapper_from: mapper_from,
      )

      config = test_class._mounted_accounting_models[:quickbooks_customer]
      expect(config[:connection_method]).to(eq(:custom_connection))
    end

    it "does not require connection_method when connection_resolver is configured" do
      allow(ActiveAccountingIntegration.config).to(receive(:connection_resolver).and_return(->(_record, _mount_name) { mock_connection }))

      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        mapper_to: mapper_to,
        mapper_from: mapper_from,
      )

      config = test_class._mounted_accounting_models[:quickbooks_customer]
      expect(config[:connection_method]).to(be_nil)
    end
  end

  describe "generated getter" do
    before do
      stub_const("TestAccountingModel", mock_accounting_class)
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        connection_method: :quickbooks_customer_connection,
        mapper_to: mapper_to,
        mapper_from: mapper_from,
      )
    end

    let(:instance) { test_class.new }

    it "returns nil when external_id is not set" do
      instance.quickbooks_customer_id = nil
      expect(instance.quickbooks_customer).to(be_nil)
    end

    it "returns nil when connection is not available" do
      instance.quickbooks_customer_id = "123"
      allow(instance).to(receive(:quickbooks_customer_connection).and_return(nil))
      expect(instance.quickbooks_customer).to(be_nil)
    end

    it "fetches and returns accounting model when external_id and connection are available" do
      instance.quickbooks_customer_id = "123"
      allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))

      result = instance.quickbooks_customer

      expect(mock_accounting_class).to(have_received(:fetch_by_id).with("123", mock_connection))
      expect(result).to(eq(mock_accounting_model))
    end

    it "caches the result and does not fetch again" do
      instance.quickbooks_customer_id = "123"
      allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))

      instance.quickbooks_customer
      instance.quickbooks_customer

      expect(mock_accounting_class).to(have_received(:fetch_by_id).once)
    end

    it "re-fetches when reload: true is passed" do
      instance.quickbooks_customer_id = "123"
      allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))

      instance.quickbooks_customer
      instance.quickbooks_customer(reload: true)

      expect(mock_accounting_class).to(have_received(:fetch_by_id).twice)
    end
  end

  describe "generated setter" do
    before do
      stub_const("TestAccountingModel", mock_accounting_class)
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        connection_method: :quickbooks_customer_connection,
        mapper_to: mapper_to,
        mapper_from: mapper_from,
      )
    end

    let(:instance) { test_class.new }

    it "sets external_id from accounting model" do
      instance.quickbooks_customer = mock_accounting_model

      expect(instance.quickbooks_customer_id).to(eq("123"))
    end

    it "caches the assigned model" do
      instance.quickbooks_customer_id = "123"
      allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))

      instance.quickbooks_customer = mock_accounting_model
      instance.quickbooks_customer

      expect(mock_accounting_class).not_to(have_received(:fetch_by_id))
    end

    it "clears cache when set to nil" do
      instance.quickbooks_customer = mock_accounting_model
      instance.quickbooks_customer = nil

      expect(instance.instance_variable_get(:@_accounting_quickbooks_customer)).to(be_nil)
    end

    it "does not change external_id when set to nil" do
      instance.quickbooks_customer_id = "existing"
      instance.quickbooks_customer = nil

      expect(instance.quickbooks_customer_id).to(eq("existing"))
    end
  end

  describe "sync_to_* method" do
    before do
      stub_const("TestAccountingModel", mock_accounting_class)
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        connection_method: :quickbooks_customer_connection,
        mapper_to: mapper_to,
        mapper_from: mapper_from,
      )
    end

    let(:instance) { test_class.new }

    context "when accounting model already exists" do
      before do
        instance.quickbooks_customer_id = "123"
        allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))
      end

      it "updates accounting model with mapped attributes and saves" do
        instance.first_name = "Jane"
        instance.last_name = "Smith"
        instance.name = "Jane Smith"

        result = instance.sync_to_quickbooks_customer

        expect(mock_accounting_model).to(have_received(:given_name=).with("Jane"))
        expect(mock_accounting_model).to(have_received(:family_name=).with("Smith"))
        expect(mock_accounting_model).to(have_received(:display_name=).with("Jane Smith"))
        expect(mock_accounting_model).to(have_received(:save))
        expect(result).to(eq(mock_accounting_model))
      end
    end

    context "when accounting model does not exist (create-on-sync)" do
      before do
        instance.quickbooks_customer_id = nil
        allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))
      end

      it "creates a new accounting model, maps attributes, and saves" do
        instance.first_name = "New"
        instance.last_name = "Customer"
        instance.name = "New Customer"

        result = instance.sync_to_quickbooks_customer

        expect(mock_accounting_class).to(have_received(:new).with(connection: mock_connection))
        expect(mock_accounting_model).to(have_received(:given_name=).with("New"))
        expect(mock_accounting_model).to(have_received(:family_name=).with("Customer"))
        expect(mock_accounting_model).to(have_received(:save))
        expect(result).to(eq(mock_accounting_model))
      end

      it "stores the new external_id after successful save" do
        instance.first_name = "New"
        instance.last_name = "Customer"
        instance.name = "New Customer"

        instance.sync_to_quickbooks_customer

        expect(instance.quickbooks_customer_id).to(eq("123"))
      end
    end

    it "returns nil when connection is not available" do
      allow(instance).to(receive(:quickbooks_customer_connection).and_return(nil))
      allow(ActiveAccountingIntegration.config).to(receive(:connection_resolver).and_return(nil))

      result = instance.sync_to_quickbooks_customer

      expect(result).to(be_nil)
    end
  end

  describe "sync_from_* method" do
    before do
      stub_const("TestAccountingModel", mock_accounting_class)
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        connection_method: :quickbooks_customer_connection,
        mapper_to: mapper_to,
        mapper_from: mapper_from,
      )
    end

    let(:instance) { test_class.new }

    before do
      instance.quickbooks_customer_id = "123"
      allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))
      allow(instance).to(receive(:save).and_return(true))
    end

    it "updates ActiveRecord model with mapped attributes from accounting model" do
      result = instance.sync_from_quickbooks_customer

      expect(instance.first_name).to(eq("John"))
      expect(instance.last_name).to(eq("Doe"))
      expect(instance.name).to(eq("John Doe"))
      expect(instance.email).to(eq("john@example.com"))
      expect(instance).to(have_received(:save))
      expect(result).to(eq(instance))
    end

    it "returns nil when accounting model is not available" do
      allow(instance).to(receive(:quickbooks_customer).and_return(nil))

      result = instance.sync_from_quickbooks_customer

      expect(result).to(be_nil)
    end
  end

  describe "connection resolution" do
    before do
      stub_const("TestAccountingModel", mock_accounting_class)
    end

    let(:instance) { test_class.new }

    context "with connection_method" do
      before do
        test_class.mounts_accounting_model(
          :quickbooks_customer,
          class_name: "TestAccountingModel",
          external_id_column: :quickbooks_customer_id,
          connection_method: :quickbooks_customer_connection,
          mapper_to: mapper_to,
          mapper_from: mapper_from,
        )
      end

      it "uses the connection_method on the instance" do
        instance.quickbooks_customer_id = "123"
        allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))

        instance.quickbooks_customer

        expect(instance).to(have_received(:quickbooks_customer_connection))
      end
    end

    context "with connection_resolver" do
      let(:resolver) { ->(_record, _mount_name) { mock_connection } }

      before do
        allow(ActiveAccountingIntegration.config).to(receive(:connection_resolver).and_return(resolver))

        test_class.mounts_accounting_model(
          :quickbooks_customer,
          class_name: "TestAccountingModel",
          external_id_column: :quickbooks_customer_id,
          mapper_to: mapper_to,
          mapper_from: mapper_from,
        )
      end

      it "uses the global connection_resolver" do
        instance.quickbooks_customer_id = "123"

        result = instance.quickbooks_customer

        expect(result).to(eq(mock_accounting_model))
      end
    end

    context "with neither connection_method nor connection_resolver" do
      before do
        allow(ActiveAccountingIntegration.config).to(receive(:connection_resolver).and_return(nil))

        test_class.mounts_accounting_model(
          :quickbooks_customer,
          class_name: "TestAccountingModel",
          external_id_column: :quickbooks_customer_id,
          mapper_to: mapper_to,
          mapper_from: mapper_from,
        )
      end

      it "returns nil from getter" do
        instance.quickbooks_customer_id = "123"

        result = instance.quickbooks_customer

        expect(result).to(be_nil)
      end
    end
  end
end
