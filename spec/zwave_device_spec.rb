require 'spec_helper'

module RZWaveWay
  describe ZWaveDevice do
    let(:now) { Time.now }
    let(:device) do
      device = ZWaveDevice.new(create_id, create_device_data)
      device.contact_frequency = 300
      device
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

      it 'updates the last contact time (from lastSend)' do
        updates = {
          'data.lastSend' => {
            'name' => 'lastSend',
            'value' => 176428709,
            'type' => 'int',
            'invalidateTime' => 1390251561,
            'updateTime' => 1409490970
          }
        }
        device.process(updates)
        expect(device.last_contact_time).to eq 1409490970
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
      context 'device is not supporting wake up command class' do
      end

      context 'device is supporting wake up command class' do
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
end
