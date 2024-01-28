# frozen_string_literal: true

module RrxConfig
  module Aws
    PROFILE_VARIABLE      = 'RRX_AWS_PROFILE'
    REGION_VARIABLE       = 'RRX_AWS_REGION'
    REGION_DEFAULT        = 'us-west-2'
    PROFILE_DEFAULT       = 'default'
    ECS_METADATA_VARIABLE = 'ECS_CONTAINER_METADATA_URI_V4'

    class << self
      def profile?
        ENV.include?(PROFILE_VARIABLE)
      end

      def profile
        ENV.fetch(PROFILE_VARIABLE, PROFILE_DEFAULT) unless Rails.env.production?
      end

      def credentials
        @credentials ||= profile_credentials || environment_credentials || ecs_credentials || ec2_credentials
      end

      def client_args
        { region:, credentials: }
      end

      def region
        ENV.fetch(REGION_VARIABLE, REGION_DEFAULT)
      end

      def profile_credentials
        if profile?
          RrxConfig.logger.info 'Using shared credentials'
          require 'aws-sdk-core/shared_credentials'
          ::Aws::SharedCredentials.new(profile_name: profile)
        end
      end

      def environment_credentials
        if ENV.include?('AWS_ACCESS_KEY_ID')
          require 'aws-sdk-core/credentials'
          RrxConfig.logger.info 'Using explicit credentials'
          ::Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
        end
      end

      def ecs_credentials
        if ENV.include?(ECS_METADATA_VARIABLE)
          RrxConfig.logger.info 'Using ECS credentials'
          require 'aws-sdk-core/ecs_credentials'
          ::Aws::ECSCredentials.new
        end
      end

      def ec2_credentials
        RrxConfig.logger.info 'Using EC2 credentials'
        require 'aws-sdk-core/instance_profile_credentials'
        ::Aws::InstanceProfileCredentials.new
      end
    end
  end
end
