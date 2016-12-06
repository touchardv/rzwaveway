module RZWaveWay
  module CommandClasses
    class Battery < CommandClass

      def property_mappings
        {
          battery_level: {
            key: 'data.last'
          }
        }
      end

      def process(updates)
        if updates.keys.include?('data.last')
          data = updates['data.last']
          value = data['value']
          updateTime = data['updateTime']
          if @device.update_property(:battery_level, value, updateTime)
            return BatteryValueEvent.new(device_id: @device.id, time: updateTime, value: value)
          end
        end
      end

      def get
        RZWaveWay::ZWay.instance.execute(@device.id, BATTERY, :Get)
      end
    end
  end
end
