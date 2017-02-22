require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe WakeUp do
      let(:command_class) { WakeUp.new(device) }
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:data) {
        {'data' => {
           'interval' => {'value' => contact_frequency, 'updateTime' => 1394983000},
           'lastSleep' => {'value' => time, 'updateTime' => time},
           'lastWakeup' => {'value' => time, 'updateTime' => time}
        }}
      }
      let(:contact_frequency) { 300 }
      let(:time) { 1394983222 }

      before { command_class.build_from(data) }

      describe '#build_from' do
        it 'adds a property for wakeup interval' do
          expect(command_class.contact_frequency).to eq 300
        end

        it 'adds a property for last sleep/wakeup time' do
          expect(command_class.last_sleep_time).to eq time
        end

        it 'updates the last contact time' do
          expect(command_class.device.last_contact_time).to eq time
        end
      end

      describe '#missed_contact_count' do
        it 'returns 0' do
          expect(command_class.missed_contact_count(time + (contact_frequency - 1))).to eq 0
        end

        it 'returns 1' do
          expect(command_class.missed_contact_count(time + contact_frequency)).to eq 1
        end
      end

      describe '#on_time?' do
        it 'returns true (wake up time not yet reached)' do
          expect(command_class.on_time?(time + (contact_frequency - 1))).to eq true
        end

        it 'returns true (wake up time reached but with small latency' do
          expect(command_class.on_time?(time + (contact_frequency + 2))).to eq true
        end

        it 'returns false' do
          expect(command_class.on_time?(time + (contact_frequency * 1.5))).to eq false
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
