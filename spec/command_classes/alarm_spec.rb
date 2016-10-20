require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe Alarm do
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:command_class) { Alarm.new(device) }

      describe '#process' do
        it 'returns an alarm event' do
          updates = File.read('spec/data/alarm.json')
          updates = JSON.parse updates
          zway = ZWay.instance
          updates_per_device = zway.send(:group_per_device, updates)
          device.process(updates_per_device[12])
        end
      end
    end
  end
end
