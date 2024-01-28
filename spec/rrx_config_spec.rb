# frozen_string_literal: true

require 'rrx_config'
require 'rrx_config/aws'

describe RrxConfig do
  let(:config) { RrxConfig::Configuration.instance }

  ##
  # Set the profile variable to enable AWS integration testing
  def self.test_aws?
    RrxConfig::Aws.profile?
  end

  def self.test_aws_iam?
    test_aws? && RrxConfig.try(:database).try(:iam)
  end

  describe RrxConfig::Environment do
    subject { RrxConfig.env }

    before do
      described_class.reset
    end

    def set_env(name)
      expect(ENV).to receive(:fetch)
                       .with(described_class::RRX_ENVIRONMENT_VARIABLE, described_class::RRX_ENVIRONMENT_DEFAULT)
                       .and_return(name)
    end

    it 'defaults to development' do
      is_expected.to be_development
    end

    it 'validates' do
      set_env 'foo'
      expect { subject }.to raise_error RrxConfig::EnvironmentError
    end

    describe 'environments' do
      using RSpec::Parameterized::TableSyntax

      where(:case_name, :short, :use_suffix) do
        'development' | 'dev' | true
        'staging'     | 'stg' | true
        'production'  | 'prd' | false
      end

      with_them do
        let(:name) { case_name }
        let(:force_suffix) { "-#{short}" }
        let(:suffix) { use_suffix ? force_suffix : '' }

        it 'reads long name from environment' do
          set_env name
          is_expected.to eq name
        end

        it 'reads short name from environment' do
          set_env short
          is_expected.to eq name
        end

        it 'get suffix' do
          set_env name
          expect(subject.suffix).to eq suffix
        end

        it 'get force suffix' do
          set_env name
          expect(subject.suffix(true)).to eq force_suffix
        end
      end
    end
  end

  describe 'current' do
    it 'should be immutable' do
      config.read
      expect { config.current.blah = 'foo' }.to raise_error(NoMethodError)
      expect { config.current.other_value }.not_to raise_error
      expect { config.current.other_value = 24 }.to raise_error(NoMethodError)
    end
  end

  describe 'railtie' do
    it 'should load config' do
      expect(config.current).to be_present
      expect(RrxConfig).to have_attributes(spec_config: true)
    end
  end

  describe 'database' do
    subject { ActiveRecord::Base.connection_db_config }
    let(:config) { subject.configuration_hash }

    it 'should configure database' do
      expect(config).to include(from_spec_config: true)
    end

    describe 'AWS IAM', if: test_aws_iam? do

      before do
        expect(RrxConfig.database).not_to respond_to :password
        expect(config).not_to include(:from_spec_config)
      end

      it 'should be connected' do
        ActiveRecord::Base.connection.exec_query 'SELECT 1'
      end

      it 'should use an IAM config' do
        is_expected.to be_a RrxConfig::IamHashConfig
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

  describe 'sources' do
    let(:expected_config) do
      {
        hello:   'there',
        meaning: 42,
        nested:  { things: [1, 'two'] }
      }
    end

    let(:be_expected_config) do
      have_attributes(
        hello:   'there',
        meaning: 42,
        nested:  have_attributes(things: [1, 'two'])
      )
    end

    let(:config_json) {
      expected_config.to_json
    }

    describe RrxConfig::Sources::EnvironmentSource do
      before do
        expect(config).to receive(:sources).and_return([described_class])
      end

      it 'should load' do
        expect(ENV).to receive(:fetch)
                         .with(described_class::VARIABLE_NAME, anything)
                         .and_return(config_json)

        config.read
        expect(RrxConfig).to be_expected_config
      end
    end

    describe RrxConfig::Sources::AwsSecretSource, if: test_aws? do
      let(:secret_name) { "rrx_config.secret_test.#{ENV['USER']}.#{Time.now.to_i}" }
      subject { described_class.new }

      before do
        allow(ENV).to receive(:fetch).and_wrap_original do |m, name, default|
          if name == described_class::SECRET_VARIABLE
            secret_name
          else
            m.call name, default
          end
        end
      end

      it 'should load' do
        subject.write config_json
        actual = subject.read

        expect(actual).to be_present
        expect(actual).to be_expected_config
      end

      after do
        subject.delete
      end
    end

    describe RrxConfig::Sources::LocalSource do
      it 'should load' do
        config.read
        expect(RrxConfig).to have_attributes(
                               spec_config: true,
                               other_value: 12,
                               some:        have_attributes(config: 'here')
                             )
      end
    end

    describe 'default' do
      it 'should set empty' do
        expect(config).to receive(:sources).and_return([])
        config.read
        expect(config.current.members).to be_empty
      end
    end
  end
end
