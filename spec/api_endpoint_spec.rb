require 'spec_helper'

describe "API endpoint: #{ENV['TEST_API_ENDPOINT']}" do
  let(:api_endpoint) { ENV['TEST_API_ENDPOINT'] }
  context 'Endpoint URL' do
    it 'exists' do
      expect(api_endpoint).to_not be_nil
    end
    it 'has a decent format' do
      expect(api_endpoint).to match(/https?:\/\/.+(:\d+)?\/wallet\/v\d/)
    end
  end
end
