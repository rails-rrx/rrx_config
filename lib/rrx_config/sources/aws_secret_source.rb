# frozen_string_literal: true

require_relative './base'
require_relative '../aws'
require_relative '../error'

module RrxConfig
  module Sources
    class AwsSecretSource < Base
      SECRET_VARIABLE  = 'RRX_AWS_CONFIG_SECRET_NAME'

      class GetAwsSecretError < Error; end

      def read
        read_secret if secret_id
      end

      ##
      # Test helper
      def write(value)
        raise NotImplementedError unless Rails.env.test?

        RrxConfig.info "Writing secret #{secret_id}"
        result = client.create_secret({
                               name:                           secret_id,
                               secret_string:                  value,
                               force_overwrite_replica_secret: true,
                               description:                    'Integration test'
                             })
        RrxConfig.info "Secret created: #{result.arn}"
      end

      ##
      # Test helper
      def delete
        raise NotImplementedError unless Rails.env.test?

        RrxConfig.info "Deleting secret #{secret_id}"
        client.delete_secret({ secret_id:, force_delete_without_recovery: true }) rescue nil
      end

      private

      def secret_id
        @secret_name ||= ENV.fetch(SECRET_VARIABLE, :-)
        @secret_name == :- ? nil : @secret_name
      end

      ##
      # @return [Aws::SecretsManager::Client]
      def client
        @client ||= begin
                      require 'aws-sdk-secretsmanager'
                      ::Aws::SecretsManager::Client.new(**Aws.client_args)
                    end
      end

      def read_secret
        read_json client.get_secret_value({secret_id:}).secret_string
      rescue x
        RrxConfig.error "Failed to read AWS secret #{secret_id}: #{x}"
        raise GetAwsSecretError, "Failed to read AWS secret #{secret_id}", x.backtrace
      end
    end
  end
end
