# frozen_string_literal: true

require 'singleton'
require_relative 'sources/local_source'
require_relative 'sources/environment_source'
require_relative 'sources/aws_secret_source'

module RrxConfig
  class Configuration
    include Singleton

    # @return [Data]
    def current
      @current ||= read
    end

    def read
      # Take the first source that returns a value
      @current = sources.inject(nil) do |current, source|
        current || source.new.read
      end || default_config
    end

    private

    def sources
      [
        Sources::EnvironmentSource,
        Sources::AwsSecretSource,
        Sources::LocalSource
      ]
    end

    def default_config
      Data.define.new
    end
  end

  def self.respond_to_missing?(...)
    Configuration.instance.current.respond_to?(...)
  end

  ##
  # Allow config values to be read directly from RrxConfig.xxxx
  def self.method_missing(name, ...)
    if name.end_with?('?')
      respond_to_missing?(name.to_s.chop.to_sym)
    else
      Configuration.instance.current.send(name, ...)
    end
  end
end
