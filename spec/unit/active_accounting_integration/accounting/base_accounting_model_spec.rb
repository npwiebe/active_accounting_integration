# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration::BaseAccountingModel) do
  let(:test_class) do
    Class.new(described_class) do
      attribute :name, Shale::Type::String
      attribute :value, Shale::Type::Float

      json do
        map "name", to: :name
        map "value", to: :value
      end

      def push_to_source
        true
      end
    end
  end

  let(:connection) { double("connection") }
  let(:attributes) { { name: "Test", value: 100.0 } }

  describe ".inherited" do
    it "defines model callbacks for the subclass" do
      expect(test_class).to(respond_to(:_create_callbacks))
      expect(test_class).to(respond_to(:_update_callbacks))
      expect(test_class).to(respond_to(:_save_callbacks))
    end

    it "adds connection validation to the subclass" do
      instance = test_class.new(attributes, connection: nil)
      expect(instance.valid?).to(be(false))
      expect(instance.errors[:connection]).to(include("is required"))
    end
  end

  describe ".fetch_by_id" do
    it "raises ActiveAccountingIntegration::UnimplementedMethodError" do
      expect { test_class.fetch_by_id("123", connection) }
        .to(raise_error(ActiveAccountingIntegration::UnimplementedMethodError, "Method fetch_by_id is not implemented in ActiveAccountingIntegration::UnimplementedMethodError"))
    end
  end

  describe ".fetch_all" do
    it "raises ActiveAccountingIntegration::UnimplementedMethodError" do
      expect { test_class.fetch_all(connection) }
        .to(raise_error(ActiveAccountingIntegration::UnimplementedMethodError, "Method fetch_all is not implemented in ActiveAccountingIntegration::UnimplementedMethodError"))
    end
  end

  describe "#initialize" do
    it "accepts connection as a keyword argument" do
      instance = test_class.new(attributes, connection: connection)
      expect(instance.connection).to(eq(connection))
    end

    it "accepts persisted as a keyword argument" do
      instance = test_class.new(attributes, connection: connection, persisted: true)
      expect(instance.persisted?).to(be(true))
    end

    it "defaults persisted to false when not specified" do
      instance = test_class.new(attributes, connection: connection)
      expect(instance.persisted?).to(be_falsey)
    end

    it "accepts connection in kwargs" do
      instance = test_class.new(attributes, connection: connection)
      expect(instance.connection).to(eq(connection))
    end
  end

  describe "#persisted?" do
    it "returns true when persisted is true" do
      instance = test_class.new(attributes, connection: connection, persisted: true)
      expect(instance.persisted?).to(be(true))
    end

    it "returns falsey when persisted is false" do
      instance = test_class.new(attributes, connection: connection, persisted: false)
      expect(instance.persisted?).to(be_falsey)
    end
  end

  describe "#[]" do
    let(:instance) do
      inst = test_class.new(connection: connection)
      inst.name = "Test"
      inst.value = 100.0
      inst
    end

    it "returns attribute value for existing attribute" do
      expect(instance[:name]).to(eq("Test"))
      expect(instance[:value]).to(eq(100.0))
    end

    it "returns nil for non-existent attribute" do
      expect(instance[:non_existent]).to(be_nil)
    end

    it "accepts string keys" do
      expect(instance["name"]).to(eq("Test"))
    end
  end

  describe "#[]=" do
    let(:instance) do
      inst = test_class.new(connection: connection)
      inst.name = "Test"
      inst.value = 100.0
      inst
    end

    it "sets attribute value for existing attribute" do
      instance[:name] = "Updated"
      expect(instance.name).to(eq("Updated"))
    end

    it "does nothing for non-existent attribute" do
      expect { instance[:non_existent] = "value" }.not_to(raise_error)
    end

    it "accepts string keys" do
      instance["name"] = "String Key"
      expect(instance.name).to(eq("String Key"))
    end
  end

  describe "#save" do
    let(:instance) do
      inst = test_class.new(connection: connection)
      inst.name = "Test"
      inst.value = 100.0
      inst
    end

    context "when valid" do
      it "returns true" do
        expect(instance.save).to(be(true))
      end

      it "calls push_to_source" do
        expect(instance).to(receive(:push_to_source).and_return(true))
        instance.save
      end
    end

    context "when invalid" do
      let(:invalid_instance) { test_class.new }

      it "returns false" do
        expect(invalid_instance.save).to(be(false))
      end

      it "does not call push_to_source" do
        expect(invalid_instance).not_to(receive(:push_to_source))
        invalid_instance.save
      end
    end

    context "when push_to_source fails" do
      before do
        allow(instance).to(receive(:push_to_source).and_return(false))
      end

      it "returns false" do
        expect(instance.save).to(be(false))
      end
    end
  end

  describe "#update" do
    let(:instance) do
      inst = test_class.new(connection: connection)
      inst.name = "Test"
      inst.value = 100.0
      inst
    end
    let(:new_attributes) { { name: "Updated", value: 200.0 } }

    it "assigns new attributes" do
      instance.update(new_attributes)
      expect(instance.name).to(eq("Updated"))
      expect(instance.value).to(eq(200.0))
    end

    it "calls save" do
      expect(instance).to(receive(:save).and_return(true))
      instance.update(new_attributes)
    end

    it "returns the result of save" do
      allow(instance).to(receive(:save).and_return(false))
      expect(instance.update(new_attributes)).to(be(false))
    end
  end

  describe "validations" do
    it "requires connection to be present" do
      instance = test_class.new
      expect(instance.valid?).to(be(false))
      expect(instance.errors[:connection]).to(include("is required"))
    end

    it "is valid when connection is present" do
      instance = test_class.new(connection: connection)
      instance.name = "Test"
      instance.value = 100.0
      expect(instance.valid?).to(be(true))
    end
  end
end
