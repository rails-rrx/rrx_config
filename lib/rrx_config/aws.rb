# frozen_string_literal: true

module RrxConfig
  module Aws
    PROFILE_VARIABLE = 'RRX_AWS_PROFILE'
    REGION_VARIABLE  = 'RRX_AWS_REGION'
    REGION_DEFAULT   = 'us-west-2'
    PROFILE_DEFAULT = 'default'

    class << self
      def profile?
        ENV.include?(PROFILE_VARIABLE)
      end

      def profile
        ENV.fetch(PROFILE_VARIABLE, PROFILE_DEFAULT) unless Rails.env.production?
      end

      def credentials
        if profile
          require 'aws-sdk-core/shared_credentials'
          ::Aws::SharedCredentials.new(profile_name: profile)
        else
          require 'aws-sdk-core/instance_profile_credentials'
          require 'aws-sdk-core/ecs_credentials'
          ec2 = ::Aws::InstanceProfileCredentials.new
          ecs = ::Aws::ECSCredentials.new
          ec2.set? ? ec2 : ecs
        end
      end

      def client_args
        { region:, credentials: }
      end

      def region
        ENV.fetch(REGION_VARIABLE, REGION_DEFAULT)
      end
    end
  end
end
