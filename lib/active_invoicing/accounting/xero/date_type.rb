# frozen_string_literal: true

require "shale"
require "date"
require "time"

module ActiveInvoicing
  module Accounting
    module Xero
      class DateType < Shale::Type::Date
        class << self
          def cast(value)
            return if value.nil? || value == "" || value.to_s.strip.empty?

            # Handle Xero's .NET date format: /Date(1234567890000)/ or /Date(1234567890000+0000)/
            match = value.to_s.match(%r{^/Date\((\d+)([+-]\d+)?\)/$})
            if match
              timestamp_ms = match[1].to_i
              timestamp_s = timestamp_ms / 1000.0

              # Handle timezone offset if present (offset is in minutes)
              if match[2]
                offset_minutes = match[2].to_i
                timestamp_s -= (offset_minutes * 60)
              end

              return Time.at(timestamp_s).utc.to_date
            end

            super(value)
          rescue StandardError => e
            warn("Failed to parse date: #{value.inspect} - #{e.message}") if ENV["DEBUG"]
            nil
          end
        end
      end
    end
  end
end
