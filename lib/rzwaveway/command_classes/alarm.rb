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
        if updates.keys.include?('data.V1event')
          event = updates['data.V1event']

          AlarmEvent.new(device_id: device.id,
                         time: event['updateTime'],
                         alarm_type: event['alarmType']['value'],
                         level: event['level']['value'])
        end
      end
    end
  end
end
