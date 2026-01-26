# frozen_string_literal: true

require "spec_helper"

RSpec.describe(ActiveAccountingIntegration) do
  describe "autoloading" do
    it "loads all accounting files" do
      expect(defined?(ActiveAccountingIntegration::Connection)).to(be_truthy)
      expect(defined?(ActiveAccountingIntegration::Quickbooks::Connection)).to(be_truthy)
      expect(defined?(ActiveAccountingIntegration::Quickbooks::Customer)).to(be_truthy)
      expect(defined?(ActiveAccountingIntegration::Quickbooks::Invoice)).to(be_truthy)
    end

    it "loads files in sorted order" do
      lib_dir = File.join(__dir__, "../../../lib/active_accounting_integration")
      files = Dir[File.join(lib_dir, "*.rb")].sort + Dir[File.join(lib_dir, "quickbooks", "*.rb")].sort

      expect(files).to(include(
        a_string_ending_with("connection.rb"),
        a_string_ending_with("quickbooks/connection.rb"),
        a_string_ending_with("quickbooks/customer.rb"),
        a_string_ending_with("quickbooks/invoice.rb"),
      ))
    end
  end
end
