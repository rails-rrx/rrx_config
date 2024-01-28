# frozen_string_literal: true

require_relative 'rrx_config/version'
require_relative 'rrx_config/configuration'
require_relative 'rrx_config/environment'
require_relative 'rrx_config/railtie'

module RrxConfig
  class << self
    def logger
      if defined?(Rails) && Rails.logger
        if Rails.logger.respond_to?(:scoped)
          Rails.logger.scoped(name: 'rrx_config')
        else
          Rails.logger
        end
      end
    end

    def log(level, msg)
      logger = self.logger
      if logger
        logger.send(level.to_sym, msg)
      else
        puts "[RRX_CONFIG][#{level.to_s.upcase}] #{msg}"
      end
    end

    def debug(msg)
      log(:debug, msg)
    end

    def info(msg)
      log(:info, msg)
    end

    def error(msg)
      log(:error, msg)
    end
  end
end
