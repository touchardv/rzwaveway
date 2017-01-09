require 'spec_helper'

module RZWaveWay
  describe Property do
    let(:property) { Property.new(value: 123, update_time: 0) }

    describe '#changed?' do
      it 'returns false when no change is performed on property' do
        expect(property.changed?).to eq false

        property.update(123, 10)
        expect(property.changed?).to eq false
      end

      it 'returns true when the value is changed' do
        property.update(456, 0)
        expect(property.changed?).to eq true
      end
    end

    describe '#read_only?' do
      it 'is false when not specified' do
        expect(property.read_only?).to eq false
      end

      it 'is true when specified to true' do
        special_property = Property.new(value: 456, update_time: 0, read_only: true)
        expect(special_property.read_only?).to eq true
      end
    end

    describe '#save' do
      it '"applies/persists" the value update' do
        property.update(456, update_time: 10)
        property.save
        expect(property.changed?).to eq false
      end
    end

    describe '#update' do
      it 'updates the value and update time' do
        property.update(456, 10)
        expect(property.value).to eq 456
        expect(property.update_time).to eq 10
      end

      it 'returns true when the value is changed' do
        result = property.update(456, 10)
        expect(result).to eq true
      end

      it 'returns false when the value is unchanged' do
        result = property.update(123, 10)
        expect(result).to eq false
      end
    end
  end
end
