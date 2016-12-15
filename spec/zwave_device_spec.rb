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
        ac_powered_device = ZWaveDevice.new(create_id, create_device_data({}, 1390252000))
        expect(ac_powered_device.last_contact_time).to eq 1390252000
      end

      it 'sets the name from data' do
        expect(device.name).to eq 'device name'
      end
    end

    describe '#add_property' do
      it 'stores a property' do
        property = { name: 'prop1', value: 123, update_time: Time.now.to_i, read_only: true }
        device.add_property(property)

        expect(device.get_property('prop1')).not_to be_nil
      end
    end

    describe '#properties' do
      it 'returns the name and value of all properties' do
        device.add_property({ name: 'prop1', value: 123, update_time: 1390252000 })
        device.add_property({ name: 'prop2', value: 456, update_time: 1390252000 })

        expect(device.properties).to eq([
                                          {name: 'prop1', value: 123, update_time: 1390252000, read_only: true},
                                          {name: 'prop2', value: 456, update_time: 1390252000, read_only: true}
        ])
      end

      it 'does not include internal properties' do
        device.add_property({ name: 'prop1', value: 123, update_time: 1390252000, internal: true })
        expect(device.properties).to be_empty
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

      it 'generates an AliveEvent when last contact time got updated' do
        device.notify_contacted(now)
        updates = {
          'data.lastReceived' => {
            'name' => 'lastReceived',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => now+100
          },
          'data.lastSend' => {
            'name' => 'lastSend',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => now+100
          }
        }
        events = device.process(updates)
        expect(events.size).to eq 1
        event = events.first
        expect(event.class).to be AliveEvent
        expect(event.device_id).to eq device.id
        expect(event.time).to eq (now+100)
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

    describe '#process_alive_check' do
      it 'generates no event' do
        device.notify_contacted(now)
        event = device.process_alive_check
        expect(event).to be_nil
      end

      it 'generates a NotAliveEvent' do
        device.notify_contacted(now - 600)
        event = device.process_alive_check
        expect(event.class).to be NotAliveEvent
        expect(event.device_id).to eq device.id
      end

      it 'does not generate a NotAliveEvent at each check' do
        device.notify_contacted(now - 600)
        event = device.process_alive_check
        event = device.process_alive_check
        expect(event).to be_nil
      end

      it 'generates a DeadEvent' do
        device.notify_contacted(now - 6000)
        event = device.process_alive_check
        expect(event.class).to be DeadEvent
        expect(event.device_id).to eq device.id
      end

      it 'does not generate a DeadEvent multiple times' do
        device.notify_contacted(now - 6000)
        event = device.process_alive_check
        event = device.process_alive_check
        expect(event).to be_nil
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
