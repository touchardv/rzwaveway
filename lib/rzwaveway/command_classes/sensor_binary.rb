module RZWaveWay
  module CommandClasses
    class SensorBinary
      include CommandClass

      def initialize(data, device)
        device.properties[:level] = find('data.1.level.value', data)
        device.properties[:last_level_update_time] = find('data.1.level.updateTime', data)
      end

      def process(updates, device)
        if updates.keys.include?('data.1')
          level_data = updates['data.1']['level']
          last_level_update_time = level_data['updateTime']
          level = level_data['value']
          return LevelEvent.new(device.id, last_level_update_time, level)
        end
      end

      def refresh_level_value(device_id)
        RZWaveWay::ZWay.instance.execute(device_id, SENSOR_BINARY, :Get)
      end
    end
  end
end
