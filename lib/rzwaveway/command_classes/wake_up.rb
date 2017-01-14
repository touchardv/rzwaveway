module RZWaveWay
  module CommandClasses
    class WakeUp < CommandClass

      def initialize(data, device)
        super

        device.contact_frequency.update(find('data.interval.value', data),
                                        find('data.interval.updateTime', data))
        device.notify_contacted(find('data.lastWakeup.value', data))
      end

      def property_mappings
        {
          wakeup_interval: {
            key: 'data.interval',
            internal: true
          },
          last_sleep_time: {
            key: 'data.lastSleep',
            internal: true
          },
          last_wakeup_time: {
            key: 'data.lastWakeup',
            internal: true
          }
        }
      end

      def process(updates)
        if updates.keys.include?('data.lastWakeup')
          data = updates['data.lastWakeup']
          value = data['value']
          update_time = data['updateTime']
          if device.last_wakeup_time.update(value, update_time)
            device.notify_contacted(value)
            return AliveEvent.new(device_id: device.id, time: value)
          end
        end

        # TODO handle change of wake up interval value?
      end
    end
  end
end
