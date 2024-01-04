# frozen_string_literal: true

require_relative 'rrx_config/version'
require_relative 'rrx_config/configuration'
require_relative 'rrx_config/environment'
require_relative 'rrx_config/database_config'

module RrxConfig
  class Error < StandardError; end

  class EnvironmentError < Error
    def initialize(msg)
      super("Invalid environment '#{msg}'")
    end
  end
end
