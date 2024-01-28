# frozen_string_literal: true

if defined?(ActiveRecord)
  require 'active_record/database_configurations'

  module RrxConfig
    class IamHashConfig < ActiveRecord::DatabaseConfigurations::HashConfig
      GLOBAL_PEM_URL='https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem'

      alias raw_configuration_hash configuration_hash

      # @param [Hash] configuration_hash
      def initialize(env_name, name, configuration_hash)
        config = configuration_hash.except(:iam)
        case config[:adapter]
        when 'mysql2'
          config[:enable_cleartext_plugin] = true
        end
        super(env_name, name, config)
      end

      def configuration_hash
        { password:, sslca:, ssl_mode: :required }.reverse_merge!(raw_configuration_hash).freeze
      end

      def password
        generator.auth_token(endpoint:, region:, user_name:)
      end

      def endpoint
        "#{raw_configuration_hash[:host]}:#{raw_configuration_hash[:port]}"
      end

      def region
        raw_configuration_hash.fetch(:region, Aws.region)
      end

      def user_name
        raw_configuration_hash[:username] || raw_configuration_hash[:user]
      end

      def generator
        require 'aws-sdk-rds'
        require_relative './aws'
        @generator ||= ::Aws::RDS::AuthTokenGenerator.new(credentials: Aws.credentials)
      end

      def sslca
        unless sslca_path.exist?
          require 'open-uri'
          download = URI.open(GLOBAL_PEM_URL)
          IO.copy_stream download, sslca_path
        end
        sslca_path.to_s
      end

      def sslca_path
        @sslca_path ||= Rails.root.join('tmp/aws-rds-ca.pem')
      end
    end

    def self.db_config_handler(env_name, name, url, config)
      case
      when url
        # Pass to default handler
        nil
      when RrxConfig.database?
        # Use config from RrxConfig
        if RrxConfig.database.try(:iam)
          IamHashConfig.new(env_name, name, RrxConfig.database.to_h)
        else
          ActiveRecord::DatabaseConfigurations::HashConfig.new(env_name, name, RrxConfig.database.to_h)
        end
      when config.fetch(:iam, false)
        # Use standard config with IAM support
        IamHashConfig.new(env_name, name, config)
      end
    end
  end

  ActiveRecord::DatabaseConfigurations.register_db_config_handler do |env_name, name, url, config|
    RrxConfig.db_config_handler env_name, name, url, config
  end
end
