module RZWaveWay
  module Extensions
    class SSASirenStrobeAlarm
      include CommandClass

      def initialize(device_id)
        @device_id = device_id
      end

      def disable
        set_value(0)
      end

      def enable
        set_value(STROBE + SIREN)
      end

      def enable_siren
        set_value(SIREN)
      end

      def enable_strobe
        set_value(STROBE)
      end

      def refresh_value
        RZWaveWay::ZWay.instance.execute(@device_id, SWITCH_MULTI_LEVEL, :Get)
      end

      private

      STROBE = 33
      SIREN = 66

      def set_value(value)
        RZWaveWay::ZWay.instance.execute(@device_id, SWITCH_MULTI_LEVEL, :Set, value)
      end
    end
  end
end
