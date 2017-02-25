require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe Battery do
      let(:command_class) { Battery.new(device) }
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:data) {
        {'data' => { 'last' => {
                       'value' => 60,
                       'type' => 'int',
                       'updateTime' => 1409681662
        }}}
      }

      before { command_class.build_from(data) }

      describe '#build_from' do
        it 'adds the battery level property' do
          expect(command_class.battery_level).to eq 60
        end
      end

      describe '#process' do
        it 'does nothing when it processes no updates' do
          expect(command_class.process({})).to be_nil
        end

        it 'yields a battery event' do
          updates = {
            'data.last' => {
              'value' => 50,
              'type' => 'int',
              'updateTime' => 1409681762
          }}
          event = nil
          command_class.process(updates) {|e| event = e}
          expect(event.class).to be RZWaveWay::BatteryValueEvent
          expect(event.value).to eq 50
          expect(event.device_id).to eq device.id
          expect(event.time).to eq 1409681762
        end
      end
    end
  end
end
