# frozen_string_literal: true

module ActiveAccountingIntegration
  class Connection
    INTEGRATIONS = {
      quickbooks: "ActiveAccountingIntegration::Quickbooks::Connection",
      # xero: "ActiveAccountingIntegration::Xero::Connection",
    }

    class << self
      def new_test_connection(integration = :quickbooks)
        return unless ActiveAccountingIntegration.configuration.sandbox_mode

        new_connection(integration, "http://localhost:3000")
      end

      def new_connection(integration, *options)
        integration_class = INTEGRATIONS[integration&.to_sym]
        if integration_class
          Object.const_get(integration_class).new(*options)
        else
          raise ArgumentError, "Unsupported integration: #{integration}"
        end
      end
    end
  end
end
