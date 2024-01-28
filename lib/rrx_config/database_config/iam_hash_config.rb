# frozen_string_literal: true

require 'active_record/database_configurations'

module RrxConfig
  module DatabaseConfig
    class IamHashConfig < ActiveRecord::DatabaseConfigurations::HashConfig
      GLOBAL_PEM_URL      = 'https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem'
      PASSWORD_EXPIRATION = 10.minutes

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
        { password:, sslca:, ssl_mode: :required }.reverse_merge!(raw_configuration_hash).freeze.tap do |it|
          if RrxConfig.logger.respond_to?(:with_tags)
            RrxConfig.logger.with_tags(**it) { RrxConfig.debug 'Generated IAM DB config' }
          else
            RrxConfig.debug "Generated IAM DB config: #{JSON(it)}"
          end
        end
      end

      def password
        if password_expired?
          @password            = generate_password
          @password_expiration = PASSWORD_EXPIRATION.from_now
        end
        @password
      end

      def password_expired?
        !(@password && @password_expiration && (@password_expiration > Time.now))
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

      def generate_password
        generator.auth_token(endpoint:, region:, user_name:)
      end

      def generator
        require 'aws-sdk-rds'
        require_relative '../aws'
        @generator ||= ::Aws::RDS::AuthTokenGenerator.new(credentials: Aws.credentials)
      end

      def sslca
        sslca_download unless sslca_path.exist?
        sslca_path.to_s
      end

      def sslca_path
        @sslca_path ||= Rails.root.join('tmp/aws-rds-ca.pem')
      end

      def sslca_download
        require 'open-uri'
        download = URI.open(GLOBAL_PEM_URL)
        sslca_path.truncate(0) if sslca_path.exist?
        IO.copy_stream download, sslca_path

        RrxConfig.info "Downloaded AWS certs to #{sslca_path}"
      end
    end

  end
end
