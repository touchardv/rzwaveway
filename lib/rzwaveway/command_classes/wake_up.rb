module RZWaveWay
  module CommandClasses
    class WakeUp < CommandClass

      def build_from(data)
        device.define_property(:contact_frequency, 'data.interval', true, data)
        device.define_property(:last_sleep_time, 'data.lastSleep', true, data)
        device.define_property(:last_wakeup_time, 'data.lastWakeup', true, data)

        last_wakeup_time = device.last_wakeup_time
        device.notify_contacted(last_wakeup_time) unless last_wakeup_time.nil?
      end

      def missed_contact_count(time = Time.now)
        (elapsed_seconds_since_last_contact(time) / device.contact_frequency).to_i
      end

      def on_time?(time = Time.now)
        elapsed_seconds_since_last_contact(time) < (device.contact_frequency * 1.2)
      end

      def process(updates)
        if updates.keys.include?('data.lastWakeup')
          data = updates['data.lastWakeup']
          value = data['value']
          update_time = data['updateTime']
          if device.properties[:last_wakeup_time].update(value, update_time)
            device.notify_contacted(value)
          end
        end
        nil
        # TODO handle change of wake up interval value?
      end

      private

      def elapsed_seconds_since_last_contact(time)
        time.to_i - device.last_contact_time
      end
    end
  end
end
