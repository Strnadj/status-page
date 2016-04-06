require 'spec_helper'

describe StatusPage do
  let(:time) { Time.local(1990) }

  before do
    StatusPage.configuration = StatusPage::Configuration.new

    Timecop.freeze(time)
  end

  let(:request) { ActionController::TestRequest.create }

  after do
    Timecop.return
  end

  describe '#configure' do
    describe 'providers' do
      it 'configures a single provider' do
        expect {
          subject.configure(&:redis)
        }.to change { StatusPage.configuration.providers }
          .to(Set.new([StatusPage::Providers::Database, StatusPage::Providers::Redis]))
      end

      it 'configures a multiple providers' do
        expect {
          subject.configure do |config|
            config.redis
            config.sidekiq
          end
        }.to change { StatusPage.configuration.providers }
          .to(Set.new([StatusPage::Providers::Database, StatusPage::Providers::Redis,
            StatusPage::Providers::Sidekiq]))
      end

      it 'appends new providers' do
        expect {
          subject.configure(&:resque)
        }.to change { StatusPage.configuration.providers }.to(
          Set.new([StatusPage::Providers::Database, StatusPage::Providers::Resque]))
      end
    end

    describe 'error_callback' do
      it 'configures' do
        error_callback = proc {}

        expect {
          subject.configure do |config|
            config.error_callback = error_callback
          end
        }.to change { StatusPage.configuration.error_callback }.to(error_callback)
      end
    end

    describe 'basic_auth_credentials' do
      it 'configures' do
        expected = {
          username: 'username',
          password: 'password'
        }

        expect {
          subject.configure do |config|
            config.basic_auth_credentials = expected
          end
        }.to change { StatusPage.configuration.basic_auth_credentials }.to(expected)
      end
    end
  end

  describe '#check' do
    context 'default providers' do
      it 'succesfully checks' do
        expect(subject.check(request: request)).to eq(
          :results => [
            'database' => {
              message: '',
              status: 'OK',
              timestamp: time.to_s(:db)
            }
          ],
          :status => :ok
        )
      end
    end

    context 'db and redis providers' do
      before do
        subject.configure do |config|
          config.database
          config.redis
        end
      end

      it 'succesfully checks' do
        expect(subject.check(request: request)).to eq(
          :results => [
            {
              'database' => {
                message: '',
                status: 'OK',
                timestamp: time.to_s(:db)
              }
            },
            {
              'redis' => {
                message: '',
                status: 'OK',
                timestamp: time.to_s(:db)
              }
            }
          ],
          :status => :ok
        )
      end

      context 'redis fails' do
        before do
          Providers.stub_redis_failure
        end

        it 'fails check' do
          expect(subject.check(request: request)).to eq(
            :results => [
              {
                'database' => {
                  message: '',
                  status: 'OK',
                  timestamp: time.to_s(:db)
                }
              },
              {
                'redis' => {
                  message: "different values (now: #{time.to_s(:db)}, fetched: false)",
                  status: 'ERROR',
                  timestamp: time.to_s(:db)
                }
              }
            ],
            :status => :service_unavailable
          )
        end
      end

      context 'sidekiq fails' do
        it 'succesfully checks' do
          expect(subject.check(request: request)).to eq(
            :results => [
              {
                'database' => {
                  message: '',
                  status: 'OK',
                  timestamp: time.to_s(:db)
                }
              },
              {
                'redis' => {
                  message: '',
                  status: 'OK',
                  timestamp: time.to_s(:db)
                }
              }
            ],
            :status => :ok
          )
        end
      end

      context 'both redis and db fail' do
        before do
          Providers.stub_database_failure
          Providers.stub_redis_failure
        end

        it 'fails check' do
          expect(subject.check(request: request)).to eq(
            :results => [
              {
                'database' => {
                  message: 'Exception',
                  status: 'ERROR',
                  timestamp: time.to_s(:db)
                }
              },
              {
                'redis' => {
                  message: "different values (now: #{time.to_s(:db)}, fetched: false)",
                  status: 'ERROR',
                  timestamp: time.to_s(:db)
                }
              }
            ],
            :status => :service_unavailable
          )
        end
      end
    end

    context 'with error callback' do
      test = false

      let(:callback) do
        proc do |e|
          expect(e).to be_present
          expect(e).to be_is_a(Exception)

          test = true
        end
      end

      before do
        subject.configure do |config|
          config.database

          config.error_callback = callback
        end

        Providers.stub_database_failure
      end

      it 'calls error_callback' do
        expect(subject.check(request: request)).to eq(
          :results => [
            {
              'database' => {
                message: 'Exception',
                status: 'ERROR',
                timestamp: time.to_s(:db)
              }
            }
          ],
          :status => :service_unavailable
        )

        expect(test).to be_truthy
      end
    end
  end
end
