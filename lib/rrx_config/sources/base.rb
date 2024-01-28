# frozen_string_literal: true

module RrxConfig
  module Sources
    class Base
      def read
        throw NotImplementedError
      end

      protected

      # @param [String, nil] value
      # @return [Data, nil]
      def read_json(value)
        if value
          result = json_to_data(JSON.parse(value, { symbolize_keys: true }))
          RrxConfig.info 'Successfully read config from %s (%s)' % [
            self.class.name.split('::').last.sub('Source', ''),
            result.members.join(', ')
          ]
          result
        else
          nil
        end
      end

      # @param [Hash] json
      def json_to_data(json)
        Configuration.hash_data(json)
      end
    end
  end
end
