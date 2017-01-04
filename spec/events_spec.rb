require 'spec_helper'

module RZWaveWay
  describe Event do
    describe '#new' do
      it 'enforces a non-nil argument' do
        expect { Event.new(nil) }
        .to raise_error ArgumentError
      end

      it 'requires a device id' do
        expect { Event.new(foo: 'bar') }
        .to raise_error ArgumentError
      end

      it 'adds a time if none is provided' do
        event = DeadEvent.new(device_id: 123)
        expect(event[:time]).not_to be_nil
      end

      it 'keeps the existing time if provided' do
        event = Event.new(device_id: 123, time: 1472373723)
        expect(event[:time]).to eq 1472373723
      end
    end
  end
end
