module RZWaveWay
  module CommandClasses
    class SwitchBinary < CommandClass

      def property_mappings
        {
          level: {
            key: 'data.level',
            read_only: false
          }
        }
      end

      def process(updates)
        if updates.keys.include?('data.level')
          data = updates['data.level']
          value = data['value']
          update_time = data['updateTime']
          if device.level.update(value, update_time)
            return LevelEvent.new(device_id: device.id, time: update_time, level: value)
          end
        end
      end

      def level
        device.properties[:level].value
      end

      def get
        RZWaveWay::ZWay.instance.execute(device.id, SWITCH_BINARY, :Get)
      end

      def set(value)
        RZWaveWay::ZWay.instance.execute(device.id, SWITCH_BINARY, :Set, value)
      end
    end
  end
end
