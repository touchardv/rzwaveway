module RZWaveWay
  module CommandClasses
    class SwitchBinary < CommandClass

      def build_from(data)
        device.define_property(:level, 'data.level', false, data)
      end

      def process(updates)
        if updates.keys.include?('data.level')
          data = updates['data.level']
          value = data['value']
          update_time = data['updateTime']
          if device.properties[:level].update(value, update_time)
            yield LevelEvent.new(device_id: device.id, time: update_time, level: value)
          end
        end
      end

      def level=(value)
        RZWaveWay::ZWay.instance.execute(device.id, SWITCH_BINARY, :Set, value)
      end

      def refresh
        RZWaveWay::ZWay.instance.execute(device.id, SWITCH_BINARY, :Get)
      end
    end
  end
end
