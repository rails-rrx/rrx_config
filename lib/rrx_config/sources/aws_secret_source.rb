# frozen_string_literal: true

require_relative './base'
require_relative '../aws'

module RrxConfig
  module Sources
    class AwsSecretSource < Base
      SECRET_VARIABLE  = 'RRX_AWS_CONFIG_SECRET_NAME'

      def read
        read_secret if secret_id
      end

      ##
      # Test helper
      def write(value)
        raise NotImplementedError unless Rails.env.test?

        puts "Writing secret #{secret_id}"
        result = client.create_secret({
                               name:                           secret_id,
                               secret_string:                  value,
                               force_overwrite_replica_secret: true,
                               description:                    'Integration test'
                             })
        puts "Secret created: #{result.arn}"
      end

      ##
      # Test helper
      def delete
        raise NotImplementedError unless Rails.env.test?

        puts "Deleting secret #{secret_id}"
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
      end
    end
  end
end
