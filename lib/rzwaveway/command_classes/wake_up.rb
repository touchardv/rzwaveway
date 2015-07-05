module RZWaveWay
  module CommandClasses
    class WakeUp
      include CommandClass

      def initialize(data, device)
        @device = device
        wakeup_interval = find('data.interval.value', data)
        last_wakeup_time = find('data.lastWakeup.value', data)
        last_sleep_time = find('data.lastSleep.value', data)

        @device.add_property(:wakeup_interval,
                             wakeup_interval,
                             find('data.interval.updateTime', data))
        @device.add_property(:wakeup_last_sleep_time,
                             last_sleep_time,
                             find('data.lastSleep.updateTime', data))
        @device.add_property(:wakeup_last_wakeup_time,
                             last_wakeup_time,
                             find('data.lastSleep.updateTime', data))

        @device.contact_frequency = wakeup_interval
        @device.notify_contacted(last_wakeup_time)
      end

      def process(updates)
        if updates.keys.include?('data.lastWakeup')
          data = updates['data.lastWakeup']
          value = data['value']
          updateTime = data['updateTime']
          if @device.update_property(:wakeup_last_wakeup_time, value, updateTime)
            @device.notify_contacted(value)
            return AliveEvent.new(@device.id, value)
          end
        end

        # TODO handle change of wake up interval value?
      end
    end
  end
end
