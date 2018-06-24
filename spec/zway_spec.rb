require 'spec_helper'

module RZWaveWay
  describe ZWay do
    let(:device_data) {
      {
        'devices' => {
          '123' => create_device_data
        }
      }
    }
    let(:http_stubs) do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get('/ZWaveAPI/Data/0') {|env| [200, {}, device_data.to_json]}
      stubs
    end
    let(:zway) do
      zway = ZWay.instance
      zway.setup({ hostname: 'dummy', polling_interval: 1 }, :test, http_stubs)
      zway
    end

    describe '#start' do
      it 'starts the library' do
        events = []
        zway.on_event(RZWaveWay::DeviceDiscoveredEvent) {|event| events << event }
        zway.start

        sleep 1
        expect(events.size).to eq 1
        expect(events.first['device_id']).to eq 123

        zway.stop
      end
    end

    context 'started' do
      before { zway.start }
      after { zway.stop }

      describe '#find_device' do
        it 'returns a device' do
          device = zway.find_device(123)
          expect(device).to be_a ZWaveDevice
        end

        it 'returns nil for an unknown device' do
          device = zway.find_device(666)
          expect(device).to be_nil
        end
      end
    end
  end
end
