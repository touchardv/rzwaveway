module RZWaveWay
  module CommandClasses
    BASIC = 32
    SENSOR_BINARY = 48
    MULTI_LEVEL_SENSOR = 49
    CONFIGURATION = 112
    BATTERY = 128
    WAKEUP = 132
    ALARM_SENSOR = 156

    DATA = {
      SENSOR_BINARY => {
        'level' => 'data.1.level.value',
        'lastLevelChangeTime' => 'data.1.level.updateTime'
      },
      WAKEUP => {
        'wakeUpInterval' => 'data.interval.value',
        'lastSleepTime' => 'data.lastSleep.value',
        'lastWakeUpTime' => 'data.lastWakeup.value'
      },
      BATTERY => {
        'batteryLevel' => 'data.last.value'
      }
    }
  end

  class CommandClass
    include CommandClasses
    attr_reader :id
    attr_reader :properties

    def initialize(id, data)
      @id = id
      @properties = {}
      if DATA.has_key? id 
        DATA[id].each do |key, name|
          @properties[key] = get_data(name, data)
        end
      end
    end

    def get_data name, data
      parts = name.split '.'
      result = data
      parts.each do | part |
        raise "Could not find part '#{part}' in '#{name}'" unless result.has_key? part
        result = result[part]
      end
      result
    end

    def process updates, device_id
      event = nil
      names = updates.keys
      case id
      when WAKEUP
        if names.include?("data.lastWakeup") &&
          names.include?("data.lastSleep")
          @properties['lastSleepTime'] = updates["data.lastSleep"]["value"]
          event = AliveEvent.new(device_id, @properties['lastSleepTime'])
        end
      when SENSOR_BINARY
        if names.include?("data.1")
          @properties['lastLevelChangeTime'] = updates['data.1']["level"]["updateTime"]
          @properties['level'] = updates['data.1']["level"]["value"]
          event = LevelEvent.new(device_id, @properties['lastLevelChangeTime'], @properties['level'])
        end
      end
      event
    end

    def process_alive_check device_id
      wakeup_interval = @properties['wakeUpInterval']
      last_sleep_time = @properties['lastSleepTime']
      current_time = Time.now.to_i
      estimated_wakeup_time = (last_sleep_time + wakeup_interval * 1.1).to_i
      if(current_time > estimated_wakeup_time)
        return NotAliveEvent.new(device_id, current_time - estimated_wakeup_time)
      end
    end
  end
end