# frozen_string_literal: true

module RrxConfig
  class Environment < ActiveSupport::StringInquirer
    RRX_ENVIRONMENT_VARIABLE = 'RRX_ENVIRONMENT'
    RRX_ENVIRONMENT_DEFAULT  = 'development'

    SHORT_NAMES = {
      'development' => 'dev',
      'staging'     => 'stg',
      'production'  => 'prd'
    }.freeze

    LONG_NAMES = SHORT_NAMES.invert.freeze

    # @param [String, nil] name Deployment environment name
    def initialize(name = nil)
      value = normalize(name || from_env)
      super(value)
      validate!
      @force_suffix = "-#{short}"
      @suffix = production? ? '' : @force_suffix
    end

    def short
      SHORT_NAMES[to_s]
    end

    def suffix(force = false) # rubocop:disable Style/OptionalBooleanParameter
      force ? @force_suffix : @suffix
    end

    def validate!
      raise RrxConfig::EnvironmentError, self unless SHORT_NAMES.key?(self)
    end

    class << self
      def instance
        @env ||= get_env
      end

      def get_env
        Environment.new
      end

      ##
      # Spec helper for testing +env+
      def reset
        @env = nil
      end
    end

    private

    def normalize(name)
      LONG_NAMES[name] || name
    end

    def from_env
      ENV.fetch(RRX_ENVIRONMENT_VARIABLE, RRX_ENVIRONMENT_DEFAULT)
    end
  end

  ##
  # Primary accessor for getting the environment
  def self.env
    Environment.instance
  end
end
