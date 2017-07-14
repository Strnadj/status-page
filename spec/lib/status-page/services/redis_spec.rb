require 'spec_helper'

describe StatusPage::Services::Redis do
  subject { described_class.new(request: test_request) }

  describe '#service_name' do
    it { expect(described_class.service_name).to eq('Redis') }
  end

  describe '#check!' do
    it 'succesfully checks' do
      expect {
        subject.check!
      }.not_to raise_error
    end

    context 'failing' do
      before do
        Services.stub_redis_failure
      end

      it 'fails check!' do
        expect {
          subject.check!
        }.to raise_error(StatusPage::Services::RedisException)
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).to be_configurable }
  end

  describe '#key' do
    it { expect(subject.send(:key)).to eq('status-redis:0.0.0.0') }
  end
end
