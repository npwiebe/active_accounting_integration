# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration) do
  # Reset the singleton instance before and after each test
  around do |example|
    Singleton.__init__(ActiveAccountingIntegration::Configuration)
    example.run
    Singleton.__init__(ActiveAccountingIntegration::Configuration)
  end

  describe ".configure" do
    it "yields the configuration instance" do
      config_instance = nil
      described_class.configure do |config|
        config_instance = config
      end

      expect(config_instance).to(be_a(ActiveAccountingIntegration::Configuration))
    end

    it "allows setting configuration values" do
      described_class.configure do |config|
        config.quickbooks_client_id = "test_client_id"
        config.quickbooks_client_secret = "test_client_secret"
        config.sandbox_mode = true
      end

      expect(described_class.configuration.quickbooks_client_id).to(eq("test_client_id"))
      expect(described_class.configuration.quickbooks_client_secret).to(eq("test_client_secret"))
      expect(described_class.configuration.sandbox_mode).to(be(true))
    end
  end

  describe ".configuration" do
    it "returns the configuration instance" do
      expect(described_class.configuration).to(be_a(ActiveAccountingIntegration::Configuration))
    end

    it "returns the same instance on multiple calls" do
      config1 = described_class.configuration
      config2 = described_class.configuration

      expect(config1).to(be(config2))
    end
  end

  describe ".config" do
    it "is an alias for configuration" do
      expect(described_class.config).to(be(described_class.configuration))
    end
  end
end

RSpec.describe(ActiveAccountingIntegration::Configuration) do
  # Reset the singleton instance before and after each test
  around do |example|
    Singleton.__init__(described_class)
    example.run
    Singleton.__init__(described_class)
  end

  let(:configuration) { described_class.instance }

  describe "singleton behavior" do
    it "is a singleton" do
      expect(described_class).to(include(Singleton))
    end

    it "returns the same instance" do
      config1 = described_class.instance
      config2 = described_class.instance

      expect(config1).to(be(config2))
    end
  end

  describe "configuration attributes" do
    it "has quickbooks_client_id attribute" do
      expect(configuration).to(respond_to(:quickbooks_client_id))
      expect(configuration).to(respond_to(:quickbooks_client_id=))
    end

    it "has quickbooks_client_secret attribute" do
      expect(configuration).to(respond_to(:quickbooks_client_secret))
      expect(configuration).to(respond_to(:quickbooks_client_secret=))
    end

    it "has sandbox_mode attribute" do
      expect(configuration).to(respond_to(:sandbox_mode))
      expect(configuration).to(respond_to(:sandbox_mode=))
    end

    it "has connection_resolver attribute" do
      expect(configuration).to(respond_to(:connection_resolver))
      expect(configuration).to(respond_to(:connection_resolver=))
    end
  end

  describe "default values" do
    it "initializes with nil values" do
      expect(configuration.quickbooks_client_id).to(be_nil)
      expect(configuration.quickbooks_client_secret).to(be_nil)
      expect(configuration.sandbox_mode).to(be_nil)
      expect(configuration.connection_resolver).to(be_nil)
    end
  end

  describe "attribute assignment" do
    it "allows setting quickbooks_client_id" do
      configuration.quickbooks_client_id = "new_client_id"
      expect(configuration.quickbooks_client_id).to(eq("new_client_id"))
    end

    it "allows setting quickbooks_client_secret" do
      configuration.quickbooks_client_secret = "new_client_secret"
      expect(configuration.quickbooks_client_secret).to(eq("new_client_secret"))
    end

    it "allows setting sandbox_mode" do
      configuration.sandbox_mode = true
      expect(configuration.sandbox_mode).to(be(true))
    end
  end

  describe "environment variable integration" do
    before do
      @original_env = ENV.to_hash
    end

    after do
      ENV.clear
      ENV.update(@original_env)
    end

    it "loads quickbooks_client_id from environment" do
      ENV["QUICKBOOKS_CLIENT_ID"] = "env_client_id"
      ActiveAccountingIntegration.configure do |config|
        config.quickbooks_client_id = ENV["QUICKBOOKS_CLIENT_ID"]
      end

      expect(ActiveAccountingIntegration.configuration.quickbooks_client_id).to(eq("env_client_id"))
    end

    it "loads quickbooks_client_secret from environment" do
      ENV["QUICKBOOKS_CLIENT_SECRET"] = "env_client_secret"
      ActiveAccountingIntegration.configure do |config|
        config.quickbooks_client_secret = ENV["QUICKBOOKS_CLIENT_SECRET"]
      end

      expect(ActiveAccountingIntegration.configuration.quickbooks_client_secret).to(eq("env_client_secret"))
    end

    it "loads sandbox_mode from environment" do
      ENV["SANDBOX_MODE"] = "true"
      ActiveAccountingIntegration.configure do |config|
        config.sandbox_mode = ENV["SANDBOX_MODE"] == "true"
      end

      expect(ActiveAccountingIntegration.configuration.sandbox_mode).to(be(true))
    end

    it "handles missing environment variables" do
      ENV.delete("QUICKBOOKS_CLIENT_ID")
      ActiveAccountingIntegration.configure do |config|
        config.quickbooks_client_id = ENV["QUICKBOOKS_CLIENT_ID"]
      end

      expect(ActiveAccountingIntegration.configuration.quickbooks_client_id).to(be_nil)
    end
  end
end
