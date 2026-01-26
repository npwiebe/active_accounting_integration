# frozen_string_literal: true

require "active_model"
require "shale"

module ActiveAccountingIntegration
  class BaseAccountingModel < Shale::Mapper
    extend ActiveModel::Callbacks
    include ActiveModel::Validations
    include ActiveModel::Dirty

    class << self
      def inherited(subclass)
        super
        subclass.define_model_callbacks(:create, :update, :save)
        subclass.validate do
          errors.add(:connection, "is required") unless connection.present?
        end
      end

      def create(attributes)
        model = new(**attributes)
        model.run_callbacks(:create) do
          return model unless model.valid?

          model.tap(&:save)
        end
      end

      def fetch_by_id(id, connection)
        raise ActiveAccountingIntegration::UnimplementedMethodError, "fetch_by_id"
      end

      def fetch_all(connection)
        raise ActiveAccountingIntegration::UnimplementedMethodError, "fetch_all"
      end
    end

    attr_reader :connection, :persisted

    def initialize(attributes = {}, connection: nil, persisted: false, **kwargs)
      @connection = connection || kwargs[:connection]
      @persisted = persisted || kwargs[:persisted]

      super(**attributes)
    end

    def persisted?
      @persisted
    end

    def [](key)
      public_send(key.to_sym) if respond_to?(key.to_sym)
    end

    def []=(key, value)
      public_send("#{key}=", value) if respond_to?("#{key}=")
    end

    def save
      run_callbacks(:save) do
        return false unless valid? && push_to_source

        changes_applied if respond_to?(:changes_applied)
        true
      end
    end

    def update(attributes = {})
      run_callbacks(:update) do
        assign_attributes(attributes)
        save
      end
    end

    private

    def assign_attributes(attributes)
      attributes.each do |key, value|
        setter = "#{key.to_sym}=".to_sym
        public_send(setter, value) if respond_to?(setter)
      end
    end

    attr_writer :connection
    attr_writer :persisted
  end
end
