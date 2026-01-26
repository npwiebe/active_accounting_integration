# frozen_string_literal: true

module ActiveAccountingIntegration
  Dir[File.join(__dir__, "*.rb")].sort.each { |file| require file unless file.end_with?("accounting.rb") }
  Dir[File.join(__dir__, "quickbooks", "*.rb")].sort.each { |file| require file }
end
