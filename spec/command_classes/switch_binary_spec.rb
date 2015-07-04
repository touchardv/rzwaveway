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

      describe '#it caches the level' do
        it 'stores interesting properties' do
          command_class
          expect(device.get_property(:level)).to eq [false, 1405102560]
        end
      end

      describe '#process' do
        it 'does nothing when it processes no updates' do
          expect(command_class.process({}, device)).to be_nil
        end

        it 'returns a multi level event' do
          updates = {
            'data.level' => {
              'value' => true,
              'updateTime' => 1405102860
          }}
          event = command_class.process(updates, device)
          expect(event.class).to be RZWaveWay::LevelEvent
          expect(event.level).to eq true
          expect(event.device_id).to eq device.id
          expect(event.time).to eq 1405102860
        end
      end
    end
  end
end
