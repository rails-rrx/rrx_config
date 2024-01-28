# frozen_string_literal: true

require 'rrx_config/database_config/iam_hash_config'

describe RrxConfig::DatabaseConfig::IamHashConfig do
  include_context :config
  include_context :aws

  let(:mock_aws) { true }
  let(:mock_sslca) { true }
  let(:expected_passwords) { 1 }
  let(:database_config) do
    {
      adapter:  'foo',
      username: 'blah',
      host:     'host.foo',
      iam:      true
    }
  end

  subject { described_class.new('env', 'name', database_config) }

  def be_password
    match(/[a-f0-9]{20}/i)
  end

  def be_iam_config
    include(database_config.except(:iam).merge(password: be_password))
  end

  before do
    if mock_aws
      expect(subject).to receive(:generate_password).exactly(expected_passwords).times do
        SecureRandom.hex(10)
      end
      allow(subject).to receive(:sslca_download).and_return(nil) if mock_sslca
    end
  end

  describe 'sslca' do
    let(:expected_passwords) { 0 }
    let(:mock_sslca) { false }

    it 'should download AWS certs' do
      subject.sslca_download
      expect(subject.sslca_path).to exist
      data = subject.sslca_path.read(200)
      expect(data).to start_with '-----BEGIN CERTIFICATE-----'
    end
  end

  describe 'configuration_hash' do
    it 'generates a password' do
      expect(subject.configuration_hash).to be_iam_config
    end

    it 'reuses unexpired password' do
      hash1 = subject.configuration_hash
      hash2 = subject.configuration_hash
      expect(hash1).to be_iam_config
      expect(hash2).to be_iam_config
      expect(hash1).to eq hash2
    end

    it 'adds SSL parameters' do
      subject.sslca_path.delete
      expect(subject).to receive(:sslca_download)
      expect(subject.configuration_hash).to include(
                                              ssl_mode: :required,
                                              sslca: match(/.*\.pem$/)
                                            )
    end

    context 'when password expired' do
      let(:expected_passwords) { 2 }

      it 'generates a new password when expired' do
        hash1 = subject.configuration_hash
        expect(hash1).to be_iam_config
        expect(subject).to receive(:password_expired?).and_return(true)

        hash2 = subject.configuration_hash
        expect(hash2).to be_iam_config
        expect(hash1).not_to eq hash2
      end
    end
  end

  ##
  # Create a run configuration that uses RRX_CONFIG to provide
  # a database configuration with iam=true and other arguments
  # for a live RDS instance that is IAM-enabled.
  describe 'integration', if: test_aws_iam? do
    let(:mock_aws) { false }

    before do
      expect(RrxConfig.database).not_to respond_to :password
      expect(config).not_to include(:from_spec_config)
    end

    it 'should be connected' do
      ActiveRecord::Base.connection.exec_query 'SELECT 1'
    end

    it 'should use an IAM config' do
      is_expected.to be_a RrxConfig::DatabaseConfig::IamHashConfig
    end

    it 'should generate a configuration hash' do
      expect(config).to include(:adapter, :host, :username, :password)
    end

    it 'should configure for every connection attempt' do
      expect(ActiveRecord::Base.connection_db_config).to receive(:password).at_least(:once).and_call_original
      ActiveRecord::Base.connection_pool.disconnect!
      ActiveRecord::Base.connection.exec_query 'SELECT 1'
    end
  end

end
