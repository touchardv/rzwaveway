module RZWaveWay
  module CommandClasses
    class SensorBinary
      include CommandClass

      def initialize(data, device)
        device.add_property(:level,
                            find('data.1.level.value', data),
                            find('data.1.level.updateTime', data))
      end

      def process(updates, device)
        if updates.keys.include?('data.1')
          data = updates['data.1']['level']
          value = data['value']
          updateTime = data['updateTime']
          if device.update_property(:level, value, updateTime)
            return LevelEvent.new(device.id, updateTime, value)
          end
        end
      end

      def refresh(device_id)
        RZWaveWay::ZWay.instance.execute(device_id, SENSOR_BINARY, :Get)
      end
    end
  end
end
