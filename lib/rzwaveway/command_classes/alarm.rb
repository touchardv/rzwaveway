module RZWaveWay
  module CommandClasses
    class Alarm < CommandClass

      # from zwayDev.pdf
      TYPE_SMOKE = 0x01
      TYPE_CO    = 0x02
      TYPE_CO2   = 0x03
      TYPE_HEAT  = 0x04
      TYPE_WATER = 0x05
      TYPE_ACCESS_CONTROL = 0x06
      TYPE_BURGLAR = 0x07
      TYPE_POWER_MANAGEMENT = 0x08
      TYPE_SYSTEM = 0x09
      TYPE_EMERGENCY = 0x0a
      TYPE_CLOCK = 0x0b

      def process(updates)
        updates.each do |key, value|
          if key == 'data.V1event'
            yield AlarmEvent.new(device_id: device.id,
                                 time: value['updateTime'],
                                 alarm_type: value['alarmType']['value'],
                                 level: value['level']['value'])
          else
            match_data = key.match(/^data.(\d+)/)
            if match_data
              alarm_type = match_data[1].to_i
              yield AlarmEvent.new(device_id: device.id,
                                   time: value['updateTime'],
                                   alarm_type: alarm_type,
                                   level: value['event']['value'])
            end
          end
        end
      end
    end
  end
end
