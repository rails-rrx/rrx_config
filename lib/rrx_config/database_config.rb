# frozen_string_literal: true

require_relative './database_config/iam_hash_config'

module RrxConfig
  module DatabaseConfig
    class << self
      def db_config_handler(env_name, name, url, config)
        case
        when url
          # Pass to default handler
          nil
        when RrxConfig.database?
          # Use config from RrxConfig
          if RrxConfig.database.try(:iam)
            config = RrxConfig.database.to_h
            RrxConfig.info "Using AWS IAM config for #{obfuscate(config)}"
            IamHashConfig.new(env_name, name, config)
          else
            ActiveRecord::DatabaseConfigurations::HashConfig.new(env_name, name, RrxConfig.database.to_h)
          end
        when config.fetch(:iam, false)
          # Use standard config with IAM support
          IamHashConfig.new(env_name, name, config)
        end
      end

      protected

      def obfuscate(config)
        if config.include?(:password)
          # @type {String}
          password          = config[:password]
          config[:password] = "#{password.length > 1 ? password[0..1] : ''}*********"
        end
        config
      end
    end
  end
end

ActiveRecord::DatabaseConfigurations.register_db_config_handler do |env_name, name, url, config|
  RrxConfig::DatabaseConfig.db_config_handler env_name, name, url, config
end
