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
        value ? json_to_data(JSON.parse(value, { symbolize_keys: true })) : nil
      end

      # @param [Hash] json
      def json_to_data(json)
        json = json.transform_values do |v|
          v.is_a?(Hash) ? json_to_data(v) : v
        end

        Data.define(*json.keys).new(**json)
      end
    end
  end
end
