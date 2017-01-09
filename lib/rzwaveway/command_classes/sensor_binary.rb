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
          update_time = data['updateTime']
          if device.level.update(value, update_time)
            return LevelEvent.new(device_id: device.id, time: update_time, level: value)
          end
        end
      end

      def level
        device.properties[:level].value
      end

      def refresh
        RZWaveWay::ZWay.instance.execute(device.id, SENSOR_BINARY, :Get)
      end
    end
  end
end
