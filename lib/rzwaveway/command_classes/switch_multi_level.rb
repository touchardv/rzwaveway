module RZWaveWay
  module CommandClasses
    class SwitchMultiLevel < CommandClass

      def property_mappings
        {
          level: {
            key: 'data.level',
            read_only: false
          }
        }
      end

      def process(updates)
        if updates.keys.include?('data.level')
          data = updates['data.level']
          value = data['value']
          update_time = data['updateTime']
          if device.level.update(value, update_time)
            return MultiLevelEvent.new(device_id: device.id, time: update_time, level: value)
          end
        end
      end

      def level
        device.level.value
      end

      def level=(value)
        RZWaveWay::ZWay.instance.execute(device.id, SWITCH_MULTI_LEVEL, :Set, value)
      end

      def refresh
        RZWaveWay::ZWay.instance.execute(device.id, SWITCH_MULTI_LEVEL, :Get)
      end
    end
  end
end
