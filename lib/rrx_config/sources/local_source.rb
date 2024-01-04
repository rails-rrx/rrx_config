# frozen_string_literal: true

require_relative './base'

module RrxConfig
  module Sources
    ##
    # Read config from local files when running locally or testing
    class LocalSource < Base
      def read
        if Rails.env.development?
          read_json_file development_config_path
        elsif Rails.env.test?
          read_json_file spec_config_path
        end
      end

      private

      # @param [Pathname] path
      def read_json_file(path)
        read_json path.read if path.exist?
      end

      def development_config_path
        @development_config_path ||= Rails.root.join('local_config.json')
      end

      def spec_config_path
        @spec_config_path ||= Rails.root.join('spec/spec_config.json')
      end
    end
  end
end
