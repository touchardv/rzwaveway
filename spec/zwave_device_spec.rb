require 'spec_helper'

module RZWaveWay
  describe ZWaveDevice do
    let(:device) do
      ZWaveDevice.new(create_id,
                      create_device_data({CommandClass::WAKEUP =>
                                          {
                                            'data' => {
                                              'interval' => { 'value' => 300, 'updateTime' => 0 },
                                              'lastSleep' => { 'value' => 1390251561, 'updateTime' => 0 },
                                              'lastWakeup' => { 'value' => 1390251561, 'updateTime' => 0 }
                                            }
                                          }
                                          }))
    end
    let(:ac_powered_device) { ZWaveDevice.new(create_id, create_device_data({}, 1390252000)) }

    describe '#new' do
      it 'sets last contact time from data (wake up command class)' do
        expect(device.last_contact_time).to eq 1390251561
      end

      it 'sets the last contact time from data (device data > wake up command class)' do
        battery_device = ZWaveDevice.new(create_id, create_device_data({CommandClass::WAKEUP =>
                                                                        {
                                                                          'data' => {
                                                                            'interval' => { 'value' => 300, 'updateTime' => 0 },
                                                                            'lastSleep' => { 'value' => 1390251000, 'updateTime' => 0 },
                                                                            'lastWakeup' => { 'value' => 1390251000, 'updateTime' => 0 }
                                                                          }
                                                                        }
                                                                        }, 1390252000))
        expect(battery_device.last_contact_time).to eq 1390252000
      end

      it 'sets the failure count' do
        expect(ac_powered_device.failure_count).to eq 0
      end

      it 'sets the is failed flag' do
        expect(ac_powered_device.is_failed).to eq false
      end

      it 'sets the last contact time from data (device data)' do
        expect(ac_powered_device.last_contact_time).to eq 1390252000
      end

      it 'sets the name from data' do
        expect(device.name).to eq 'device name'
      end
    end

    describe '#contacts_controller_periodically?' do
      it 'returns true if device supports wake up cc' do
        expect(device.contacts_controller_periodically?).to be true
      end

      it 'returns false if device does not support wake up cc' do
        ac_powered_device = ZWaveDevice.new(create_id, create_device_data)
        expect(ac_powered_device.contacts_controller_periodically?).to be false
      end
    end

    describe '#notify_contacted' do
      it 'updates the last contact time' do
        now = Time.now.to_i
        device.notify_contacted(now)
        expect(device.last_contact_time).to eq now
      end

      it 'does not update the last contact time' do
        now = Time.now.to_i
        device.notify_contacted(now)
        expect(device.last_contact_time).to eq now
        device.notify_contacted(now - 600)
        expect(device.last_contact_time).to eq now
      end
    end

    describe '#process' do
      let(:updates) {
        {
          'data.lastReceived' => {
            'name' => 'lastReceived',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => 1409490977
          }
        }
      }

      let(:name_update) {
        {
          'data.givenName' => {
            'name' => 'givenName',
            'value' => 'foobar',
            'updateTime' => 1409490977
          }
        }
      }

      it 'updates the last contact time (from lastReceived)' do
        device.process(updates)
        expect(device.last_contact_time).to eq 1409490977
      end

      it 'generates a event when updated' do
        events = []
        device.process(name_update) {|event| events << event}
        expect(events.size).to eq 1
        expect(events.first).to be_a DeviceUpdatedEvent
      end
    end

    describe '#properties' do
      it 'returns a Hash' do
        expect(device.properties.class).to eq Hash
      end
    end
  end
end
