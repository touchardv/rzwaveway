module RZWaveWay
  module CommandClasses
    class Battery
      include CommandClass

      def initialize(data, device)
        device.add_property(:battery_level,
                            find('data.last.value', data),
                            find('data.last.updateTime', data))
      end

      def process(updates, device)
        if updates.keys.include?('data.last')
          data = updates['data.last']
          value = data['value']
          updateTime = data['updateTime']
          if device.update_property(:battery_level, value, updateTime)
            return BatteryValueEvent.new(device.id, updateTime, value)
          end
        end
      end

      def refresh(device_id)
        RZWaveWay::ZWay.instance.execute(device_id, BATTERY, :Get)
      end
    end
  end
end
