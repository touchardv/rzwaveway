module RZWaveWay
  module CommandClasses
    class WakeUp
      include CommandClass

      def initialize(data, device)
        wakeUpInterval = find('data.interval.value', data)
        lastSleepTime = find('data.lastSleep.value', data)
        lastWakeUpTime = find('data.lastWakeup.value', data)
        device.contact_frequency = wakeUpInterval
        device.notify_contacted(lastWakeUpTime)
      end

      def process(updates, device)
        if updates.keys.include?('data.lastWakeup')
          last_wakeup_time = updates['data.lastWakeup']['value']
          device.notify_contacted(last_wakeup_time)
          return AliveEvent.new(device.id, last_wakeup_time)
        end
      end
    end
  end
end
