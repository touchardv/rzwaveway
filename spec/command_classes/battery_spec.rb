require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe Battery do
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:command_class) do
        Battery.new(
          {'data' => { 'last' => {
                         'value' => 60,
                         'type' => 'int',
                         'updateTime' => 1409681662
        }}}, device)
      end

      describe '#new' do
        it 'adds the battery level property' do
          command_class
          expect(device.battery_level.value).to eq 60
          expect(device.battery_level.update_time).to eq 1409681662
        end
      end

      describe '#process' do
        it 'does nothing when it processes no updates' do
          expect(command_class.process({})).to be_nil
        end

        it 'returns a battery event' do
          updates = {
            'data.last' => {
              'value' => 50,
              'type' => 'int',
              'updateTime' => 1409681762
          }}
          event = command_class.process(updates)
          expect(event.class).to be RZWaveWay::BatteryValueEvent
          expect(event.value).to eq 50
          expect(event.device_id).to eq device.id
          expect(event.time).to eq 1409681762
        end
      end
    end
  end
end
