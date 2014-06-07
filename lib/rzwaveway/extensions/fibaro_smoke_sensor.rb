module RZWaveWay
  module Extensions
    class FibaroSmokeSensor
      include CommandClasses

      def initialize(device_id)
        @device_id = device_id
      end

      def refresh_temperature
        RZWaveWay::ZWay.instance.execute(@device_id, SENSOR_MULTI_LEVEL, :Get)
      end
    end
  end
end
