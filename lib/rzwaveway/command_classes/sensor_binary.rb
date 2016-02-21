module RZWaveWay
  module CommandClasses
    class SensorBinary
      include CommandClass

      def initialize(data, device)
        @device = device
        @device.add_property(name: :level,
                             value: find('data.1.level.value', data),
                             update_time: find('data.1.level.updateTime', data))
      end

      def process(updates)
        if updates.keys.include?('data.1')
          data = updates['data.1']['level']
          value = data['value']
          updateTime = data['updateTime']
          if @device.update_property(:level, value, updateTime)
            return LevelEvent.new(@device.id, updateTime, value)
          end
        end
      end

      def level
        @device.get_property(:level)[0]
      end

      def get
        RZWaveWay::ZWay.instance.execute(@device.id, SENSOR_BINARY, :Get)
      end
    end
  end
end
