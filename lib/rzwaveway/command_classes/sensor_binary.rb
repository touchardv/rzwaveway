module RZWaveWay
  module CommandClasses
    class SensorBinary < CommandClass

      def property_mappings
        {
          level: {
            key: 'data.1.level'
          }
        }
      end

      def process(updates)
        if updates.keys.include?('data.1')
          data = updates['data.1']['level']
          value = data['value']
          updateTime = data['updateTime']
          if device.update_property(:level, value, updateTime)
            return LevelEvent.new(device_id: device.id, time: updateTime, level: value)
          end
        end
      end

      def level
        device.get_property(:level)[0]
      end

      def refresh
        RZWaveWay::ZWay.instance.execute(device.id, SENSOR_BINARY, :Get)
      end
    end
  end
end
