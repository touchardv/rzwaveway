module RZWaveWay
  module CommandClasses
    BASIC = 32
    SENSOR_BINARY = 48
    MULTI_LEVEL_SENSOR = 49
    CONFIGURATION = 112
    ALARM = 113
    MANUFACTURER_SPECIFIC = 114
    BATTERY = 128
    WAKEUP = 132
    ASSOCIATION = 133
    VERSION = 134
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

    ALIVE_CHECK_RETRY_DELAYS_IN_MINUTES = [1, 5, 15, 30, 60, 120]

    def initialize(id, data)
      @id = id
      @alive_check_failed_count = 0
      @next_alive_check_time = 0
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
        if names.include?("data.lastWakeup") && @properties['lastWakeUpTime'] < updates["data.lastWakeup"]["value"] &&
          names.include?("data.lastSleep") && @properties['lastSleepTime'] < updates["data.lastSleep"]["value"]
          @alive_check_failed_count = 0
          @next_alive_check_time = 0
          @properties['lastWakeUpTime'] = updates["data.lastWakeup"]["value"]
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
      current_time = Time.now.to_i
      if(current_time >= @next_alive_check_time)
        wakeup_interval = @properties['wakeUpInterval']
        last_sleep_time = @properties['lastSleepTime']
        unless(wakeup_interval && last_sleep_time)
          return
        end
        estimated_wakeup_time = last_sleep_time + (wakeup_interval * 1.1)
        if(current_time > estimated_wakeup_time)
          retry_delay_in_minutes = ALIVE_CHECK_RETRY_DELAYS_IN_MINUTES[@alive_check_failed_count]
          if(retry_delay_in_minutes)
            @next_alive_check_time = current_time + retry_delay_in_minutes * 60
            @alive_check_failed_count += 1
            return NotAliveEvent.new(device_id, current_time - estimated_wakeup_time)
          else
            return DeadEvent.new(device_id)
          end
        else
          @next_alive_check_time = estimated_wakeup_time
          nil
        end
      end
    end
  end
end