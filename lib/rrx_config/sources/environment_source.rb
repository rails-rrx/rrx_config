# frozen_string_literal: true

require_relative './base'

module RrxConfig
  module Sources
    class EnvironmentSource < Base
      VARIABLE_NAME = 'RRX_CONFIG'

      # @return [Struct, nil]
      def read
        read_json ENV.fetch(VARIABLE_NAME, nil)
      end
    end
  end
end
