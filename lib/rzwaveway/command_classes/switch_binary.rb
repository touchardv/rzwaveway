module RZWaveWay
  module CommandClasses
    class SwitchBinary < CommandClass

      def property_mappings
        {
          level: {
            key: 'data.level'
          }
        }
      end

      def process(updates)
        if updates.keys.include?('data.level')
          data = updates['data.level']
          value = data['value']
          updateTime = data['updateTime']
          if @device.update_property(:level, value, updateTime)
            return LevelEvent.new(device_id: @device.id, time: updateTime, level: value)
          end
        end
      end

      def level
        @device.get_property(:level)[0]
      end

      def get
        RZWaveWay::ZWay.instance.execute(@device.id, SWITCH_BINARY, :Get)
      end

      def set(value)
        RZWaveWay::ZWay.instance.execute(@device.id, SWITCH_BINARY, :Set, value)
      end
    end
  end
end
