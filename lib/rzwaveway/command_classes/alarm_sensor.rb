module RZWaveWay
  module CommandClasses
    class AlarmSensor < CommandClass
      GENERAL_PURPOSE = 0x00
      SMOKE = 0x01
      CO = 0x02
      CO2 = 0x03
      HEAT = 0x04
      WATER_LEAK = 0x05

      def process(updates)
        log.info updates
        nil
      end
    end
  end
end
