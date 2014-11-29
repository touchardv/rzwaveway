module RZWaveWay
  module CommandClasses
    class SwitchMultiLevel
      include CommandClass

      def initialize(data, device)
        device.add_property(:level,
                            find('data.level.value', data),
                            find('data.level.updateTime', data))
      end

      def process(updates, device)
        if updates.keys.include?('data.level')
          data = updates['data.level']
          value = data['value']
          updateTime = data['updateTime']
          if device.update_property(:level, value, updateTime)
            return MultiLevelEvent.new(device.id, updateTime, value)
          end
        end
      end

      def refresh_value device_id
        RZWaveWay::ZWay.instance.execute(device_id, SWITCH_MULTI_LEVEL, :Get)
      end

      def set_value(value, device_id)
        RZWaveWay::ZWay.instance.execute(device_id, SWITCH_MULTI_LEVEL, :Set, value)
      end
    end
  end
end
