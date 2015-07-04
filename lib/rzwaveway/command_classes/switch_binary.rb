module RZWaveWay
  module CommandClasses
    class SwitchBinary
      include CommandClass

      def initialize(data, device)
        @device = device
        @device.add_property(:level,
                             find('data.level.value', data),
                             find('data.level.updateTime', data))
      end

      def process(updates, device)
        if updates.keys.include?('data.level')
          data = updates['data.level']
          value = data['value']
          updateTime = data['updateTime']
          if device.update_property(:level, value, updateTime)
            return LevelEvent.new(device.id, updateTime, value)
          end
        end
      end

      def level
        @device.get_property(:level)[0]
      end

      def get
        RZWaveWay::ZWay.instance.execute(@device.id, SWITCH_BINARY, :Get)
      end

      def set value
        RZWaveWay::ZWay.instance.execute(@device.id, SWITCH_BINARY, :Set, value)
      end
    end
  end
end
