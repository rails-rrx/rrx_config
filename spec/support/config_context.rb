# frozen_string_literal: true

require 'rrx_config'

shared_context :config do
  let(:config) { RrxConfig::Configuration.instance }

  def set_config(hash)
    new_config = RrxConfig::Configuration.hash_data(hash)
    expect(config).to receive(:current).at_least(:once).and_return(new_config)
  end
end
