# frozen_string_literal: true

require 'rrx_config/aws'

shared_context :aws do
  def self.test_aws?
    RrxConfig::Aws.profile?
  end

  def self.test_aws_iam?
    test_aws? && RrxConfig.try(:database).try(:iam)
  end
end
