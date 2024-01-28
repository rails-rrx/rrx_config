# frozen_string_literal: true

describe RrxConfig::Railtie do
  include_context :config

  it 'should load config' do
    expect(config.current).to be_present
    expect(RrxConfig).to have_attributes(spec_config: true)
  end

  it 'should configure database' do
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    expect(config).to include(from_spec_config: true)
  end
end
