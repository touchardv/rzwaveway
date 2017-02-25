require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe SwitchBinary do
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:command_class) { SwitchBinary.new(device) }
      let(:data) {
        {'data' => { 'level' => {
                       'value' => false,
                       'updateTime' => 1405102560
        }}}
      }

      describe '#build_from' do
        it 'adds a property for level' do
          command_class.build_from(data)
          expect(command_class.level).to eq false
        end
      end

      describe '#process' do
        before { command_class.build_from(data) }

        it 'does nothing when it processes no updates' do
          expect(command_class.process({})).to be_nil
        end

        it 'yields a multi level event' do
          updates = {
            'data.level' => {
              'value' => true,
              'updateTime' => 1405102860
          }}
          event = nil
          command_class.process(updates) {|e| event = e}
          expect(event.class).to be RZWaveWay::LevelEvent
          expect(event.level).to eq true
          expect(event.device_id).to eq device.id
          expect(event.time).to eq 1405102860
        end
      end
    end
  end
end
