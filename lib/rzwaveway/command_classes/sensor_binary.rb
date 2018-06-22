module RZWaveWay
  module CommandClasses
    class SensorBinary < CommandClass

      def build_from(data)
        device.define_property(:level, 'data.1.level', true, data)
      end

      def process(updates)
        if updates.keys.include?('data.1')
          data = updates['data.1']['level']
          value = data['value']
          update_time = data['updateTime']
          if device.properties[:level].update(value, update_time)
            yield LevelEvent.new(device_id: device.id, time: update_time, level: value)
          end
        end
      end

      def refresh
        RZWaveWay::ZWay.instance.execute(device.id, SENSOR_BINARY, :Get)
      end
    end
  end
end
