require 'spec_helper'

module RZWaveWay
  describe PropertiesCache do
    class Test
      include PropertiesCache
    end

    let(:cache) { Test.new }
    let(:data) {
      {
        'foo' => {
          'value' => 'bar',
          'updateTime' => 123
        },
        'oof' => {
          'value' => 'rab',
          'updateTime' => 1
        }
      }
    }

    before { cache.define_property(:foo, 'foo', false, data) }

    describe '#define_property' do

      it 'adds a property' do
        expect(cache.properties.size).to eq 1
        expect(cache.properties[:foo]).to be_a Property
        expect(cache.properties[:foo].value).to eq 'bar'
        expect(cache.properties[:foo].update_time).to eq 123
        expect(cache.properties[:foo].read_only?).to eq false
      end

      it 'defines a helper method' do
        expect(cache.foo).to eq 'bar'
      end

      it 'raises when trying to add an already existing property' do
        expect { cache.define_property(:foo, 'foo', false, data) } .to raise_error(ArgumentError)
      end
    end

    describe '#properties_changed?' do
      it 'returns false' do
        expect(cache.properties_changed?).to eq false
      end

      it 'returns true' do
        cache.properties[:foo].update('boom', 666)
        expect(cache.properties_changed?).to eq true
      end
    end
  end
end
