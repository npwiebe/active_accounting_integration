# frozen_string_literal: true

require "singleton"

module ActiveAccountingIntegration
  class Configuration
    include Singleton

    attr_accessor :quickbooks_client_id, :quickbooks_client_secret, :sandbox_mode, :connection_resolver

    def initialize
      @quickbooks_client_id = nil
      @quickbooks_client_secret = nil
      @sandbox_mode = nil
      @connection_resolver = nil
    end
  end

  class << self
    def configuration
      Configuration.instance
    end

    def config
      configuration
    end

    def configure
      yield(configuration)
    end
  end
end

ActiveAccountingIntegration.configure do |config|
  config.quickbooks_client_id = ENV["QUICKBOOKS_CLIENT_ID"]
  config.quickbooks_client_secret = ENV["QUICKBOOKS_CLIENT_SECRET"]
  config.sandbox_mode = ENV["SANDBOX_MODE"] == "true"
end
