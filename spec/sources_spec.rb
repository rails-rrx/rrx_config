# frozen_string_literal: true

describe RrxConfig::Sources do
  include_context :config
  include_context :aws

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
