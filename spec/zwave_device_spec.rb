require 'spec_helper'

module RZWaveWay
  describe ZWaveDevice do
    let(:now) { Time.now }
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

      it 'sets the last contact time from data (device data)' do
        expect(ac_powered_device.last_contact_time).to eq 1390252000
      end

      it 'sets the name from data' do
        expect(device.name).to eq 'device name'
      end
    end

    describe '#add_property' do
      let(:property1) { Property.new(value: 123, update_time: Time.now.to_i, read_only: true) }

      it 'stores a property' do
        device.add_property('prop1', property1)

        expect(device.properties['prop1']).not_to be_nil
      end

      it 'creates a method for accessing the property' do
        device.add_property('prop1', property1)

        expect(device.prop1.value).to eq 123
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
      it 'updates the last contact time (from lastReceived)' do
        updates = {
          'data.lastReceived' => {
            'name' => 'lastReceived',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => 1409490977

          }
        }
        device.process(updates)
        expect(device.last_contact_time).to eq 1409490977
      end

      it 'updates the last contact time' do
        updates = {
          'data.lastReceived' => {
            'name' => 'lastReceived',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => 1409490977
          },
          'data.lastSend' => {
            'name' => 'lastSend',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => 1409490970
          }
        }
        device.process(updates)
        expect(device.last_contact_time).to eq 1409490977
      end

      it 'does not generate an AliveEvent when last contact time is not updated' do
        device.notify_contacted(now)
        updates = {
          'data.lastReceived' => {
            'name' => 'lastReceived',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => 1409490970
          },
          'data.lastSend' => {
            'name' => 'lastSend',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => 1409490970
          }
        }
        events = device.process(updates)
        expect(events.size).to eq 0
      end
    end

    describe '#to_json' do
      it 'returns json' do
        json = device.to_json
        expect(json.size).not_to eq 0
      end
    end
  end
end
