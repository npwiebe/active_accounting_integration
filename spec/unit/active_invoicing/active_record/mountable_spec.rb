# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveInvoicing::ActiveRecord::Mountable) do
  let(:test_class) do
    Class.new do
      include ActiveInvoicing::ActiveRecord::Mountable

      # Mock ActiveRecord methods
      attr_accessor :name, :email, :first_name, :last_name, :quickbooks_customer_id

      def assign_attributes(attrs)
        attrs.each { |k, v| public_send("#{k}=", v) }
      end

      def save
        true
      end

      # Mock connection method - will be stubbed in tests
      def quickbooks_customer_connection
        nil
      end

      def quickbooks_customer_custom_connection
        nil
      end

      def quickbooks_customer_separate_connection
        nil
      end

      # Set up respond_to? expectations for common attributes
      def respond_to?(method_name, include_private = false)
        case method_name.to_s
        when "name=", "email=", "first_name=", "last_name="
          true
        else
          super
        end
      end
    end
  end

  let(:mock_connection) { double("connection") }
  let(:mock_accounting_model) do
    double("accounting_model").tap do |model|
      allow(model).to(receive(:external_id).and_return("123"))
      allow(model).to(receive(:name).and_return("Test Customer"))
      allow(model).to(receive(:email).and_return("test@example.com"))
      allow(model).to(receive(:first_name).and_return("John"))
      allow(model).to(receive(:last_name).and_return("Doe"))
      # Add common attributes that the new mapping tries
      allow(model).to(receive(:company_name).and_return("Test Company"))
      allow(model).to(receive(:phone).and_return("555-1234"))
      allow(model).to(receive(:address).and_return("123 Main St"))
      allow(model).to(receive(:city).and_return("Anytown"))
      allow(model).to(receive(:state).and_return("CA"))
      allow(model).to(receive(:zip_code).and_return("12345"))
      allow(model).to(receive(:country).and_return("USA"))
      allow(model).to(receive(:description).and_return("Test description"))
      allow(model).to(receive(:notes).and_return("Test notes"))
      allow(model).to(receive(:balance).and_return(100.0))
      allow(model).to(receive(:total).and_return(200.0))
      allow(model).to(receive(:amount).and_return(150.0))
      allow(model).to(receive(:price).and_return(50.0))
      allow(model).to(receive(:cost).and_return(40.0))
      allow(model).to(receive(:quantity).and_return(2))
      allow(model).to(receive(:tax_rate).and_return(0.08))
      allow(model).to(receive(:discount).and_return(10.0))
      allow(model).to(receive(:due_date).and_return(Date.today))
      allow(model).to(receive(:invoice_date).and_return(Date.today))
      allow(model).to(receive(:paid_at).and_return(Date.today))

      # Set up respond_to? expectations for common attributes
      allow(model).to(receive(:respond_to?).and_return(true)) # Allow any respond_to? call by default
      allow(model).to(receive(:respond_to?).with(:name).and_return(true))
      allow(model).to(receive(:respond_to?).with(:email).and_return(true))
      allow(model).to(receive(:respond_to?).with(:first_name).and_return(true))
      allow(model).to(receive(:respond_to?).with(:last_name).and_return(true))
      allow(model).to(receive(:respond_to?).with("name=").and_return(true))
      allow(model).to(receive(:respond_to?).with("email=").and_return(true))
      allow(model).to(receive(:respond_to?).with("first_name=").and_return(true))
      allow(model).to(receive(:respond_to?).with("last_name=").and_return(true))
      allow(model).to(receive(:respond_to?).with("company_name=").and_return(true))
      allow(model).to(receive(:respond_to?).with(:name=).and_return(true))
      allow(model).to(receive(:respond_to?).with(:email=).and_return(true))
      allow(model).to(receive(:respond_to?).with(:first_name=).and_return(true))
      allow(model).to(receive(:respond_to?).with(:last_name=).and_return(true))
      allow(model).to(receive(:respond_to?).with(:company_name=).and_return(true))
      allow(model).to(receive(:save))
    end
  end

  let(:mock_accounting_class) do
    double("accounting_class").tap do |klass|
      allow(klass).to(receive(:fetch_by_id).and_return(mock_accounting_model))

      allow(klass).to(receive(:attributes).and_return({
        name: double(name: :name, setter: "name="),
        email: double(name: :email, setter: "email="),
        first_name: double(name: :first_name, setter: "first_name="),
        last_name: double(name: :last_name, setter: "last_name="),
        company_name: double(name: :company_name, setter: "company_name="),
      }))
    end
  end

  describe ".mounts_accounting_model" do
    before do
      allow(mock_accounting_class).to(receive(:fetch_by_id).and_return(mock_accounting_model))
    end

    it "stores configuration in class attribute" do
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
      )

      config = test_class._mounted_accounting_models[:quickbooks_customer]
      expect(config[:class_name]).to(eq("TestAccountingModel"))
      expect(config[:external_id_column]).to(eq(:quickbooks_customer_id))
      expect(config[:connection_method]).to(eq("quickbooks_customer_connection"))
    end

    it "allows custom connection method" do
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        connection_method: :custom_connection,
      )

      config = test_class._mounted_accounting_models[:quickbooks_customer]
      expect(config[:connection_method]).to(eq(:custom_connection))
    end

    it "stores custom mapper" do
      mapper = proc { {} }
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
        mapper: mapper,
      )

      config = test_class._mounted_accounting_models[:quickbooks_customer]
      expect(config[:mapper]).to(eq(mapper))
    end
  end

  describe "generated methods" do
    before do
      stub_const("TestAccountingModel", mock_accounting_class)
      test_class.mounts_accounting_model(
        :quickbooks_customer,
        class_name: "TestAccountingModel",
        external_id_column: :quickbooks_customer_id,
      )
    end

    let(:instance) { test_class.new }

    describe "getter method" do
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
    end

    describe "setter method" do
      it "sets external_id from accounting model" do
        instance.quickbooks_customer = mock_accounting_model

        expect(instance.quickbooks_customer_id).to(eq("123"))
      end

      it "does nothing if accounting model is nil" do
        instance.quickbooks_customer_id = "existing"
        instance.quickbooks_customer = nil

        expect(instance.quickbooks_customer_id).to(eq("existing"))
      end
    end

    describe "sync_to_* method" do
      before do
        instance.quickbooks_customer_id = "123"
        allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))
        allow(mock_accounting_model).to(receive(:save))
        allow(mock_accounting_model).to(receive(:name=))
        allow(mock_accounting_model).to(receive(:email=))
      end

      it "updates accounting model with default mapping" do
        instance.name = "Updated Name"
        instance.email = "updated@example.com"

        result = instance.sync_to_quickbooks_customer

        expect(mock_accounting_model).to(have_received(:name=).with("Updated Name"))
        expect(mock_accounting_model).to(have_received(:email=).with("updated@example.com"))
        expect(mock_accounting_model).to(have_received(:save))
        expect(result).to(eq(mock_accounting_model))
      end

      it "uses custom mapper when provided" do
        custom_mapper = proc do |accounting_model|
          { name: "Custom #{name}", custom_field: "value" }
        end

        # Remount with custom mapper
        stub_const("TestAccountingModel", mock_accounting_class)
        test_class.mounts_accounting_model(
          :quickbooks_customer_custom,
          class_name: "TestAccountingModel",
          external_id_column: :quickbooks_customer_id,
          mapper: custom_mapper,
        )

        allow(mock_accounting_model).to(receive(:custom_field=))
        instance.name = "Test"
        allow(instance).to(receive(:quickbooks_customer_custom_connection).and_return(mock_connection))

        result = instance.sync_to_quickbooks_customer_custom

        expect(mock_accounting_model).to(have_received(:name=).with("Custom Test"))
        expect(mock_accounting_model).to(have_received(:custom_field=).with("value"))
        expect(result).to(eq(mock_accounting_model))
      end

      it "returns nil when accounting model is not available" do
        allow(instance).to(receive(:quickbooks_customer).and_return(nil))

        result = instance.sync_to_quickbooks_customer

        expect(result).to(be_nil)
      end
    end

    describe "sync_from_* method" do
      before do
        instance.quickbooks_customer_id = "123"
        allow(instance).to(receive(:quickbooks_customer_connection).and_return(mock_connection))
        allow(instance).to(receive(:save).and_return(true))
      end

      it "updates ActiveRecord model with default mapping" do
        result = instance.sync_from_quickbooks_customer

        expect(instance.name).to(eq("Test Customer"))
        expect(instance.email).to(eq("test@example.com"))
        expect(instance.first_name).to(eq("John"))
        expect(instance.last_name).to(eq("Doe"))
        expect(instance).to(have_received(:save))
        expect(result).to(eq(instance))
      end

      it "uses custom mapper when provided" do
        custom_mapper = proc do |accounting_model|
          {
            name: "#{accounting_model.name} (Mapped)",
            email: accounting_model.email.upcase,
          }
        end

        # Remount with custom mapper
        stub_const("TestAccountingModel", mock_accounting_class)
        test_class.mounts_accounting_model(
          :quickbooks_customer_custom,
          class_name: "TestAccountingModel",
          external_id_column: :quickbooks_customer_id,
          mapper: custom_mapper,
        )

        allow(instance).to(receive(:quickbooks_customer_custom_connection).and_return(mock_connection))

        result = instance.sync_from_quickbooks_customer_custom

        expect(instance.name).to(eq("Test Customer (Mapped)"))
        expect(instance.email).to(eq("TEST@EXAMPLE.COM"))
        expect(result).to(eq(instance))
      end

      it "uses separate mapper_to and mapper_from when provided" do
        mapper_to = proc do |accounting_model|
          # Rails -> Accounting
          {
            display_name: "#{first_name} #{last_name}",
            primary_email_address: { address: email },
          }
        end

        mapper_from = proc do |accounting_model|
          # Accounting -> Rails
          {
            first_name: accounting_model.given_name,
            last_name: accounting_model.family_name,
            email: accounting_model.primary_email_address&.address,
          }
        end

        mock_accounting_model_with_names = double("accounting_model").tap do |model|
          allow(model).to(receive(:external_id).and_return("123"))
          allow(model).to(receive(:given_name).and_return("Jane"))
          allow(model).to(receive(:family_name).and_return("Smith"))
          allow(model).to(receive(:primary_email_address).and_return(double(address: "jane@example.com")))
          allow(model).to(receive(:display_name=))
          allow(model).to(receive(:primary_email_address=))
          allow(model).to(receive(:save))
        end

        mock_accounting_class_with_names = double("accounting_class").tap do |klass|
          allow(klass).to(receive(:fetch_by_id).and_return(mock_accounting_model_with_names))
        end

        stub_const("TestAccountingModel", mock_accounting_class_with_names)
        test_class.mounts_accounting_model(
          :quickbooks_customer_separate,
          class_name: "TestAccountingModel",
          external_id_column: :quickbooks_customer_id,
          mapper_to: mapper_to,
          mapper_from: mapper_from,
        )

        instance.first_name = "John"
        instance.last_name = "Doe"
        instance.email = "john@example.com"
        instance.quickbooks_customer_id = "123"
        allow(instance).to(receive(:quickbooks_customer_separate_connection).and_return(mock_connection))

        # Test sync_to direction
        result_to = instance.sync_to_quickbooks_customer_separate
        expect(mock_accounting_model_with_names).to(have_received(:display_name=).with("John Doe"))
        expect(mock_accounting_model_with_names).to(have_received(:primary_email_address=).with({ address: "john@example.com" }))

        # Test sync_from direction
        result_from = instance.sync_from_quickbooks_customer_separate
        expect(instance.first_name).to(eq("Jane"))
        expect(instance.last_name).to(eq("Smith"))
        expect(instance.email).to(eq("jane@example.com"))
      end

      it "returns nil when accounting model is not available" do
        allow(instance).to(receive(:quickbooks_customer).and_return(nil))

        result = instance.sync_from_quickbooks_customer

        expect(result).to(be_nil)
      end
    end
  end

  describe ".default_connection_method" do
    it "generates connection method name from mounted model name" do
      expect(test_class.send(:default_connection_method, :quickbooks_customer)).to(eq("quickbooks_customer_connection"))
      expect(test_class.send(:default_connection_method, :xero_contact)).to(eq("xero_contact_connection"))
    end
  end

  describe "#default_map_to_accounting_model" do
    let(:instance) do
      test_class.new.tap do |obj|
        obj.name = "Test Company"
        obj.email = "test@example.com"
        obj.first_name = "John"
        obj.last_name = "Doe"
      end
    end

    it "maps common attributes that exist on both models" do
      attributes = instance.send(:default_map_to_accounting_model, mock_accounting_model)

      expect(attributes[:name]).to(eq("Test Company"))
      expect(attributes[:email]).to(eq("test@example.com"))
      expect(attributes[:first_name]).to(eq("John"))
      expect(attributes[:last_name]).to(eq("Doe"))
      expect(attributes[:company_name]).to(be_nil) # not set
    end

    it "excludes attributes that don't exist on accounting model" do
      test_model = double("accounting_model")
      allow(test_model).to(receive(:respond_to?).with("name=").and_return(false))
      allow(test_model).to(receive(:respond_to?).with("email=").and_return(true))
      allow(test_model).to(receive(:respond_to?).with("first_name=").and_return(true))
      allow(test_model).to(receive(:respond_to?).with("last_name=").and_return(true))
      allow(test_model).to(receive(:respond_to?).with("company_name=").and_return(true))

      attributes = instance.send(:default_map_to_accounting_model, test_model)

      expect(attributes[:name]).to(be_nil)
      expect(attributes[:email]).to(eq("test@example.com"))
    end

    it "excludes blank values" do
      instance.name = ""
      instance.email = nil

      attributes = instance.send(:default_map_to_accounting_model, mock_accounting_model)

      expect(attributes[:name]).to(be_nil)
      expect(attributes[:email]).to(be_nil)
      expect(attributes[:first_name]).to(eq("John"))
    end
  end

  describe "#default_map_from_accounting_model" do
    let(:instance) { test_class.new }

    it "maps common attributes that exist on both models" do
      attributes = instance.send(:default_map_from_accounting_model, mock_accounting_model)

      expect(attributes[:name]).to(eq("Test Customer"))
      expect(attributes[:email]).to(eq("test@example.com"))
      expect(attributes[:first_name]).to(eq("John"))
      expect(attributes[:last_name]).to(eq("Doe"))
    end

    it "excludes attributes that don't exist on ActiveRecord model" do
      test_instance = test_class.new
      # Allow all respond_to? calls by default, then override specific ones
      allow(test_instance).to(receive(:respond_to?).and_return(true))
      allow(test_instance).to(receive(:respond_to?).with("name=").and_return(false))

      attributes = test_instance.send(:default_map_from_accounting_model, mock_accounting_model)

      expect(attributes[:name]).to(be_nil)
      expect(attributes[:email]).to(eq("test@example.com"))
    end

    it "excludes blank values from accounting model" do
      blank_accounting_model = double(
        "accounting_model",
        name: "",
        email: nil,
        first_name: "John",
        last_name: "Doe",
      )

      attributes = instance.send(:default_map_from_accounting_model, blank_accounting_model)

      expect(attributes[:name]).to(be_nil)
      expect(attributes[:email]).to(be_nil)
      expect(attributes[:first_name]).to(eq("John"))
      expect(attributes[:last_name]).to(eq("Doe"))
    end
  end
end
