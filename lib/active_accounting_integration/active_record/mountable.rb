# frozen_string_literal: true

require "active_support/concern"

module ActiveAccountingIntegration
  module ActiveRecord
    module Mountable
      extend ActiveSupport::Concern

      included do
        class_attribute :_mounted_accounting_models, default: {}
      end

      module ClassMethods
        def mounts_accounting_model(name, class_name:, external_id_column:, mapper_to:, mapper_from:, connection_method: nil, sync_on_save: false)
          name = name.to_sym
          class_name = class_name.to_s
          connection_method = connection_method&.to_sym
          external_id_column = external_id_column.to_sym

          self._mounted_accounting_models = _mounted_accounting_models.merge(
            name => {
              class_name: class_name,
              connection_method: connection_method,
              external_id_column: external_id_column,
              mapper_to: mapper_to,
              mapper_from: mapper_from,
            },
          )

          define_accounting_getter(name)
          define_accounting_setter(name)
          define_sync_to(name)
          define_sync_from(name)
        end

        private

        def define_accounting_getter(name)
          define_method(name) do |reload: false|
            ivar = "@_accounting_#{name}"
            if instance_variable_defined?(ivar) && !reload
              return instance_variable_get(ivar)
            end

            config = self.class._mounted_accounting_models[name]
            return unless config

            external_id = public_send(config[:external_id_column])
            return unless external_id

            connection = resolve_accounting_connection(name, config)
            return unless connection

            accounting_class = config[:class_name].constantize
            result = accounting_class.fetch_by_id(external_id, connection)
            instance_variable_set(ivar, result)
            result
          end
        end

        def define_accounting_setter(name)
          define_method("#{name}=") do |accounting_model|
            ivar = "@_accounting_#{name}"

            if accounting_model.nil?
              instance_variable_set(ivar, nil)
              return
            end

            config = self.class._mounted_accounting_models[name]
            return unless config

            external_id = accounting_model.id
            public_send("#{config[:external_id_column]}=", external_id) if external_id
            instance_variable_set(ivar, accounting_model)
          end
        end

        def define_sync_to(name)
          define_method("sync_to_#{name}") do
            config = self.class._mounted_accounting_models[name]
            return unless config

            connection = resolve_accounting_connection(name, config)
            return unless connection

            accounting_model = public_send(name)

            if accounting_model.nil?
              accounting_class = config[:class_name].constantize
              accounting_model = accounting_class.new(connection: connection)
            end

            attributes = instance_exec(accounting_model, &config[:mapper_to])

            attributes.each do |key, value|
              setter = "#{key}="
              accounting_model.public_send(setter, value) if accounting_model.respond_to?(setter)
            end

            if accounting_model.save
              public_send("#{config[:external_id_column]}=", accounting_model.id) if accounting_model.id
              instance_variable_set("@_accounting_#{name}", accounting_model)
            end

            accounting_model
          end
        end

        def define_sync_from(name)
          define_method("sync_from_#{name}") do
            config = self.class._mounted_accounting_models[name]
            return unless config

            accounting_model = public_send(name)
            return unless accounting_model

            attributes = instance_exec(accounting_model, &config[:mapper_from])

            assign_attributes(attributes)
            save
            self
          end
        end
      end

      private

      def resolve_accounting_connection(name, config)
        if config[:connection_method]
          public_send(config[:connection_method])
        elsif ActiveAccountingIntegration.config.connection_resolver
          ActiveAccountingIntegration.config.connection_resolver.call(self, name)
        end
      end
    end
  end
end
