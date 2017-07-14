require 'spec_helper'

describe StatusPage::Services::Database do
  subject { described_class.new(request: test_request) }

  describe '#service_name' do
    it { expect(described_class.service_name).to eq('Database') }
  end

  describe '#check!' do
    it 'succesfully checks' do
      expect {
        subject.check!
      }.not_to raise_error
    end

    context 'failing' do
      before do
        Services.stub_database_failure
      end

      it 'fails check!' do
        expect {
          subject.check!
        }.to raise_error(StatusPage::Services::DatabaseException)
      end
    end
  end

  describe '#configurable?' do
    it { expect(described_class).not_to be_configurable }
  end
end
