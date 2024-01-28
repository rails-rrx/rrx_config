# frozen_string_literal: true

require 'rrx_config/database_config'

describe RrxConfig::DatabaseConfig do
  include_context :config

  let(:fake_url) { 'blah://fake' }
  let(:fake_config) { { some: 'config' } }
  let(:iam_config) { { some: 'config', iam: true } }

  def no_database
    set_config({})
  end

  it 'should ignore URL configs' do
    expect(described_class.db_config_handler('env', 'blah', fake_url, fake_config)).to be_nil
  end

  it 'should passthrough database.yml config when no database config' do
    no_database
    expect(described_class.db_config_handler('env', 'blah', nil, fake_config)).to be_nil
  end

  it 'should create IAM config for database.yml config' do
    no_database
    result = described_class.db_config_handler('env', 'blah', nil, iam_config)
    expect(result).to be_a RrxConfig::DatabaseConfig::IamHashConfig
    expect(result.raw_configuration_hash).to match iam_config.except(:iam)
  end

  it 'should override database.yml' do
    result = described_class.db_config_handler('env', 'blah', nil, fake_config)
    expect(result).to be_a ActiveRecord::DatabaseConfigurations::HashConfig
    expect(result.configuration_hash).to include(from_spec_config: true)
    expect(result.configuration_hash).not_to match fake_config
  end

  it 'should create IAM config' do
    set_config({database: iam_config})
    result = described_class.db_config_handler('env', 'blah', nil, fake_config)
    expect(result).to be_a RrxConfig::DatabaseConfig::IamHashConfig
    expect(result.raw_configuration_hash).to match iam_config.except(:iam)
  end
end
