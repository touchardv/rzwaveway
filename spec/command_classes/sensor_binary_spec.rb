require 'spec_helper'

module RZWaveWay
  module CommandClasses
    describe SensorBinary do
      let(:command_class) { SensorBinary.new(device) }
      let(:device) { ZWaveDevice.new(create_id, create_device_data) }
      let(:data) {
        {'data' => { '1' => { 'level' => {
                                'value' => false,
                                'updateTime' => 1405102560
        }}}}
      }

      before { command_class.build_from(data) }

      describe '#build_from' do
        it 'adds a property for level' do
          expect(device.level).to eq false
        end
      end

      describe '#process' do
        it 'does nothing when it processes no updates' do
          expect(command_class.process({})).to be_nil
        end

        it 'yields a level event' do
          updates = {
            'data.1' => { 'level' => {
                            'value' => true,
                            'updateTime' => 1405102860
          }}}
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
