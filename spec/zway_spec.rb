require 'spec_helper'

module RZWaveWay
  describe ZWay do
    let(:http_stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:zway) do
      zway = ZWay.instance
      zway.setup({ hostname: 'dummy' }, :test, http_stubs)
      zway
    end

    describe '#start' do
      it 'starts the library' do
        http_stubs.get('/ZWaveAPI/Data/0') {|env| [200, {}, { devices: {}}.to_json]}
        zway.start
        expect(zway.devices.size).to eq 0
      end

      it 'starts the library, even when ZWay HTTP is ready later' do
        Thread.new do
          sleep(1)
          http_stubs.get('/ZWaveAPI/Data/0') {|env| [200, {}, '{}']}
          sleep(2)
          http_stubs.get('/ZWaveAPI/Data/') {|env| [200, {}, { devices: {}}.to_json]}
        end
        zway.start
        expect(zway.devices.size).to eq 0
      end
    end
  end
end
