module RZWaveWay
  module CommandClasses
    SENSOR_BINARY = 48
    MULTI_LEVEL_SENSOR = 49
    CONFIGURATION = 112
    BATTERY = 128
    WAKEUP = 132
    ALARM_SENSOR = 156
  end

  class CommandClass
    include CommandClasses
    attr_reader :id
    @data

    def initialize(id, data)
      @id = id
      @data = data
    end

    def get_data name
      parts = name.split '.'
      result = @data
      parts.each do | part |
        raise "Could not find part '#{part}' in '#{name}'" unless result.has_key? part
        result = result[part]
      end
      result
    end

    def process updates, device_id
      event = nil
      names = updates.collect { |x| x[0]}
      case id
      when WAKEUP
        if names.include?("data.lastWakeup") &&
          names.include?("data.lastSleep")
          event = AliveEvent.new(device_id, updates[1][1]["value"])
        end
      when SENSOR_BINARY
        if names.include?("data.1")
          event = LevelEvent.new(device_id,updates[0][1]["level"]["updateTime"], updates[0][1]["level"]["value"])
        end
      end
      event
    end
  end
end