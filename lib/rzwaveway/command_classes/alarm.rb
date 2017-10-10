module RZWaveWay
  module CommandClasses
    class Alarm < CommandClass

      def process(updates)
        updates.each do |key, value|
          if key == 'data.V1event'
            alarm_type = value['alarmType']['value']
            yield AlarmEvent.new(device_id: device.id,
                                 time: value['updateTime'],
                                 alarm_type: ALARM_TYPES[alarm_type],
                                 level: value['level']['value'])
          else
            match_data = key.match(/^data.(\d+)/)
            if match_data
              alarm_type = match_data[1].to_i
              yield AlarmEvent.new(device_id: device.id,
                                   time: value['updateTime'],
                                   alarm_type: ALARM_TYPES[alarm_type],
                                   level: value['event']['value'])
            end
          end
        end
      end

      private

      ALARM_TYPES = {
        0x01 => :smoke,
        0x02 => :co,
        0x03 => :co2,
        0x04 => :heat,
        0x05 => :water,
        0x06 => :access_control,
        0x07 => :burglar,
        0x08 => :power_management,
        0x09 => :system,
        0x0a => :emergency,
        0x0b => :clock
      }
    end
  end
end
