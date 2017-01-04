module RZWaveWay
  module Extensions
    class SSASirenStrobeAlarm
      def initialize device
        @device = device
      end

      def disable
        set DISABLED
      end

      def enable
        set(STROBE + SIREN)
      end

      def enable_siren
        set SIREN
      end

      def enable_strobe
        set STROBE
      end

      def level
        case @device.SwitchMultiLevel.level
        when DISABLED
          :disabled
        when STROBE
          :strobe
        when SIREN
          :siren
        else
          :strobe_and_siren
        end
      end

      private

      DISABLED = 0
      STROBE = 33
      SIREN = 66

      def set level
        @device.SwitchMultiLevel.level = level
      end
    end
  end
end
