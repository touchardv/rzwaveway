require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe SwitchBinary do
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:command_class) do
        SwitchBinary.new(
          {'data' => { 'level' => {
                         'value' => false,
                         'updateTime' => 1405102560
        }}}, device)
      end

      describe '#new' do
        it 'adds a property for level' do
          command_class
          expect(device.level.value).to eq false
          expect(device.level.update_time).to eq 1405102560
        end
      end

      describe '#process' do
        it 'does nothing when it processes no updates' do
          expect(command_class.process({})).to be_nil
        end

        it 'returns a multi level event' do
          updates = {
            'data.level' => {
              'value' => true,
              'updateTime' => 1405102860
          }}
          event = command_class.process(updates)
          expect(event.class).to be RZWaveWay::LevelEvent
          expect(event.level).to eq true
          expect(event.device_id).to eq device.id
          expect(event.time).to eq 1405102860
        end
      end
    end
  end
end
