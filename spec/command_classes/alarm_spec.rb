require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe Alarm do
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:command_class) { Alarm.new({}, device) }

      describe '#process' do
        it 'returns an alarm event' do
          updates = File.read('spec/data/alarm.json')
          updates = JSON.parse updates
          zway = ZWay.instance
          updates_per_device = zway.send(:group_per_device, updates)
          updates_per_cc = device.send(:group_per_commandclass, updates_per_device[12])
          event = command_class.process(updates_per_cc[113])
          expect(event.alarm_type).to eq 8
          expect(event.level).to eq 2
        end
      end
    end
  end
end
