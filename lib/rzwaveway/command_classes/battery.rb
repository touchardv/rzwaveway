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
          update_time = data['updateTime']
          if device.battery_level.update(value, update_time)
            return BatteryValueEvent.new(device_id: device.id, time: update_time, value: value)
          end
        end
      end

      def refresh
        RZWaveWay::ZWay.instance.execute(device.id, BATTERY, :Get)
      end
    end
  end
end
