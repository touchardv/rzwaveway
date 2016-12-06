module RZWaveWay
  module CommandClasses
    class Alarm < CommandClass

      def property_mappings
        {}
      end

      def process(updates)
        if updates.keys.include?('data.V1event')
          event = updates['data.V1event']

          AlarmEvent.new(device_id: @device.id,
                         time: event['updateTime'],
                         alarm_type: event['alarmType']['value'],
                         level: event['level']['value'])
        end
      end
    end
  end
end
