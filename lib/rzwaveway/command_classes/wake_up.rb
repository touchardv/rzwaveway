module RZWaveWay
  module CommandClasses
    class WakeUp
      include CommandClass

      def initialize(data, device)
        @device = device
        wakeup_interval = find('data.interval.value', data)
        last_wakeup_time = find('data.lastWakeup.value', data)
        last_sleep_time = find('data.lastSleep.value', data)

        @device.add_property(name: :wakeup_interval,
                             value: wakeup_interval,
                             update_time: find('data.interval.updateTime', data),
                             internal: true)
        @device.add_property(name: :wakeup_last_sleep_time,
                             value: last_sleep_time,
                             update_time: find('data.lastSleep.updateTime', data),
                             internal: true)
        @device.add_property(name: :wakeup_last_wakeup_time,
                             value: last_wakeup_time,
                             update_time: find('data.lastWakeup.updateTime', data),
                             internal: true)

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
