# frozen_string_literal: true

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
      'staging' | 'stg' | true
      'production' | 'prd' | false
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
