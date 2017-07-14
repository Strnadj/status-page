require 'spec_helper'

describe StatusPage::Services::Sidekiq do
  describe StatusPage::Services::Sidekiq::Configuration do
    describe 'defaults' do
      it { expect(described_class.new.latency).to eq(30) }
    end
  end

  subject { described_class.new(request: test_request) }

  before do
    redis_conn = proc { Redis.new }

    Sidekiq.configure_client do |config|
      config.redis = ConnectionPool.new(&redis_conn)
    end

    Sidekiq.configure_server do |config|
      config.redis = ConnectionPool.new(&redis_conn)
    end
  end

  describe '#service_name' do
    it { expect(described_class.service_name).to eq('Sidekiq') }
  end

  describe '#check!' do
    it 'succesfully checks' do
      Services.stub_sidekiq_progresses_online
      expect {
        subject.check!
      }.not_to raise_error
    end

    context 'failing' do
      context 'workers' do
        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(StatusPage::Services::SidekiqException)
        end
      end

      context 'latency' do
        before do
          Services.stub_sidekiq_latency_failure
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(StatusPage::Services::SidekiqException)
        end
      end

      context 'redis' do
        before do
          Services.stub_sidekiq_redis_failure
        end

        it 'fails check!' do
          expect {
            subject.check!
          }.to raise_error(StatusPage::Services::SidekiqException)
        end
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).to be_configurable }
  end

  describe '#configure' do
    it 'latency can be configured' do
      latency = 123

      expect {
        described_class.config.latency = latency
      }.to change { described_class.config.latency }.to(latency)
    end
  end
end
