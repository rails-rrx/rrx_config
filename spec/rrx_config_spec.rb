# frozen_string_literal: true

describe RrxConfig do
  include_context :config

  describe 'current' do
    it 'should be immutable' do
      config.read
      expect { config.current.blah = 'foo' }.to raise_error(NoMethodError)
      expect { config.current.other_value }.not_to raise_error
      expect { config.current.other_value = 24 }.to raise_error(NoMethodError)
    end
  end
end
