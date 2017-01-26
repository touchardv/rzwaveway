require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe WakeUp do
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:command_class) { WakeUp.new(device) }
      let(:data) {
        {'data' => {
           'interval' => {'value' => 300, 'updateTime' => 1394983000},
           'lastSleep' => {'value' => 1394983222, 'updateTime' => 1394983222},
           'lastWakeup' => {'value' => 1394983222, 'updateTime' => 1394983222}
        }}
      }

      describe '#build_from' do
        it 'adds a property for wakeup interval' do
          command_class.build_from(data)
          expect(command_class.contact_frequency).to eq 300
        end

        it 'adds a property for last sleep/wakeup time' do
          command_class.build_from(data)
          expect(command_class.last_sleep_time).to eq 1394983222
        end

        it 'updates the last contact time' do
          command_class.build_from(data)
          expect(device.last_contact_time).to eq 1394983222
        end
      end

      describe '#process' do
        before { command_class.build_from(data) }

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
