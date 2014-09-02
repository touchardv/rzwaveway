module RZWaveWay
  module CommandClasses
    class Battery
      include CommandClass

      def initialize(data, device)
        device.properties[:battery_level] = find('data.last.value', data)
      end

      def process(updates, device)
        if updates.keys.include?('data.last')
          value = updates['data.last']['value']
          time = updates['data.last']['updateTime']
          return BatteryValueEvent.new(device.id, time, value)
        end
      end

      def refresh(device_id)
        RZWaveWay::ZWay.instance.execute(device_id, BATTERY, :Get)
      end
    end
  end
end
