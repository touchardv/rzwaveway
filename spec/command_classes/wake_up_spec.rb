require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe WakeUp do
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:command_class) do
        WakeUp.new(
          {'data' => {
             'interval' => {'value' => 300, 'updateTime' => 1394983000},
             'lastSleep' => {'value' => 1394983222, 'updateTime' => 1394983222},
             'lastWakeup' => {'value' => 1394983222, 'updateTime' => 1394983222}
        }}, device)
      end

      describe '#new' do
        it 'adds a property for wakeup interval' do
          command_class
          expect(device.wakeup_interval.value).to eq 300
          expect(device.wakeup_interval.update_time).to eq 1394983000
        end

        it 'updates the contact frequency' do
          command_class
          expect(device.contact_frequency.value).to eq 300
        end

        it 'adds a property for last sleep/wakeup time' do
          command_class
          expect(device.last_sleep_time.value).to eq 1394983222
          expect(device.last_wakeup_time.value).to eq 1394983222
        end

        it 'updates the last contact time' do
          command_class
          expect(device.last_contact_time).to eq 1394983222
        end
      end

      describe '#process' do
        it 'does nothing when it processes no updates' do
          expect(command_class.process({})).to be_nil
        end

        it 'updates the last contact time' do
          updates = {
            'data.lastWakeup' => {'value' => 1395247772, 'updateTime' => 1395247772},
            'data.lastSleep' => {'value' => 1395247772, 'updateTime' => 1395247772}
          }
          event = command_class.process(updates)
          expect(device.last_contact_time).to eq 1395247772
        end
      end
    end
  end
end
