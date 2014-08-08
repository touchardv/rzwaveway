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
