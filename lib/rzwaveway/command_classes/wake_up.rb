module RZWaveWay
  module CommandClasses
    class WakeUp < CommandClass

      def build_from(data)
        define_property(:contact_frequency, 'data.interval', true, data)
        define_property(:last_sleep_time, 'data.lastSleep', true, data)
        define_property(:last_wakeup_time, 'data.lastWakeup', true, data)

        device.notify_contacted(find('data.lastWakeup.value', data))
      end

      def process(updates)
        if updates.keys.include?('data.lastWakeup')
          data = updates['data.lastWakeup']
          value = data['value']
          update_time = data['updateTime']
          if @properties[:last_wakeup_time].update(value, update_time)
            device.notify_contacted(value)
          end
        end
        nil
        # TODO handle change of wake up interval value?
      end
    end
  end
end
