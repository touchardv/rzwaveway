module RZWaveWay
  module CommandClasses
    class SwitchMultiLevel
      include CommandClass

      def initialize(data, device)
        @device = device
        @device.add_property(name: :level,
                             value: find('data.level.value', data),
                             update_time: find('data.level.updateTime', data),
                             read_only: false)
      end

      def process(updates)
        if updates.keys.include?('data.level')
          data = updates['data.level']
          value = data['value']
          updateTime = data['updateTime']
          if @device.update_property(:level, value, updateTime)
            return MultiLevelEvent.new(device_id: @device.id, time: updateTime, level: value)
          end
        end
      end

      def level
        @device.get_property(:level)[0]
      end

      def get
        RZWaveWay::ZWay.instance.execute(@device.id, SWITCH_MULTI_LEVEL, :Get)
      end

      def set(value)
        RZWaveWay::ZWay.instance.execute(@device.id, SWITCH_MULTI_LEVEL, :Set, value)
      end
    end
  end
end
