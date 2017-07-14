require 'spec_helper'

describe StatusPage do
  let(:time) { Time.local(1990) }

  before do
    allow(StatusPage).to receive(:config).and_return(StatusPage::Configuration.new)
    allow(StatusPage.config).to receive(:interval).and_return(0)

    Timecop.freeze(time)
  end

  let(:request) { test_request }

  after do
    Timecop.return
  end

  describe '#configure' do
    describe 'providers' do
      it 'configures a single provider' do
        expect {
          subject.configure do
            self.use :redis
          end
        }.to change { StatusPage.config.providers }
          .to(Set.new([StatusPage::Services::Redis]))
      end

      it 'configures a multiple providers' do
        expect {
          subject.configure do
            self.use :redis
            self.use :sidekiq
          end
        }.to change { StatusPage.config.providers }
          .to(Set.new([StatusPage::Services::Redis, StatusPage::Services::Sidekiq]))
      end

      it 'appends new providers' do
        expect {
          subject.configure do
            self.use :resque
          end
        }.to change { StatusPage.config.providers }.to(
          Set.new([StatusPage::Services::Resque]))
      end
    end

    describe 'error_callback' do
      it 'configures' do
        error_callback = proc {}

        expect {
          subject.configure do
            self.error_callback = error_callback
          end
        }.to change { StatusPage.config.error_callback }.to(error_callback)
      end
    end

    describe 'basic_auth_credentials' do
      it 'configures' do
        expected = {
          username: 'username',
          password: 'password'
        }

        expect {
          subject.configure do
            self.basic_auth_credentials = expected
          end
        }.to change { StatusPage.config.basic_auth_credentials }.to(expected)
      end
    end
  end

  describe '#check' do
    context 'default providers' do
      it 'succesfully checks' do
        expect(subject.check(request: request)).to eq(
          :results => [],
          :status => :ok,
          :timestamp => time
        )
      end
    end

    context 'db and redis providers' do
      before do
        subject.configure do
          self.use :database
          self.use :redis
        end
      end

      it 'succesfully checks' do
        expect(subject.check(request: request)).to eq(
          :results => [
            {
              name: 'Database',
              message: '',
              status: 'OK'
            },
            {
              name: 'Redis',
              message: '',
              status: 'OK'
            }
          ],
          :status => :ok,
          :timestamp => time
        )
      end

      context 'redis fails' do
        before do
          Services.stub_redis_failure
        end

        it 'fails check' do
          expect(subject.check(request: request)).to eq(
            :results => [
              {
                name: 'Database',
                message: '',
                status: 'OK'
              },
              {
                name: 'Redis',
                message: "different values (now: #{time.to_s(:db)}, fetched: false)",
                status: 'ERROR'
              }
            ],
            :status => :service_unavailable,
            :timestamp => time
          )
        end
      end

      context 'sidekiq fails' do
        it 'succesfully checks' do
          expect(subject.check(request: request)).to eq(
            :results => [
              {
                name: 'Database',
                message: '',
                status: 'OK'
              },
              {
                name: 'Redis',
                message: '',
                status: 'OK'
              }
            ],
            :status => :ok,
            :timestamp => time
          )
        end
      end

      context 'both redis and db fail' do
        before do
          Services.stub_database_failure
          Services.stub_redis_failure
        end

        it 'fails check' do
          expect(subject.check(request: request)).to eq(
            :results => [
              {
                name: 'Database',
                message: 'Exception',
                status: 'ERROR'
              },
              {
                name: 'Redis',
                message: "different values (now: #{time.to_s(:db)}, fetched: false)",
                status: 'ERROR'
              }
            ],
            :status => :service_unavailable,
            :timestamp => time
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
        that = self
        subject.configure do
          self.use :database

          self.error_callback = that.callback
        end

        Services.stub_database_failure
      end

      it 'calls error_callback' do
        expect(subject.check(request: request)).to eq(
          :results => [
            {
              name: 'Database',
              message: 'Exception',
              status: 'ERROR'
            }
          ],
          :status => :service_unavailable,
          :timestamp => time
        )

        expect(test).to be_truthy
      end
    end
  end
end
