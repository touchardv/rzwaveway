require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe SwitchMultiLevel do
      let(:command_class) { SwitchMultiLevel.new(device) }
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:data) {
        {'data' => { 'level' => {
                       'value' => 33,
                       'updateTime' => 1405102560
        }}}
      }

      before { command_class.build_from(data) }

      describe '#build_from' do
        it 'adds a property for level' do
          expect(command_class.level).to eq 33
        end
      end

      describe '#process' do
        it 'does nothing when it processes no updates' do
          expect(command_class.process({})).to be_nil
        end

        it 'yields a multi level event' do
          updates = {
            'data.level' => {
              'value' => 66,
              'updateTime' => 1405102860
          }}
          event = nil
          command_class.process(updates) {|e| event = e}
          expect(event.class).to be RZWaveWay::MultiLevelEvent
          expect(event.level).to eq 66
          expect(event.device_id).to eq device.id
          expect(event.time).to eq 1405102860
        end
      end
    end
  end
end
