module RZWaveWay
  module CommandClasses
    class Battery
      extend CommandClass

      def initialize(data, device)
        device.properties[:battery_level] = find('data.last.value', data)
      end

      def process(updates, device)
      end
    end
  end
end
