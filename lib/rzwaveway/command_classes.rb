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

    MAXIMUM_WAKEUP_MISSED_COUNT = 10

    def initialize(id, data)
      @dead = false
      @id = id
      @wakeup_missed_count = 0
      @next_wakeup_check_time = 0
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
        if names.include?("data.lastWakeup") && @properties['lastWakeUpTime'] < updates["data.lastWakeup"]["value"]
          @dead = false
          @wakeup_missed_count = 0
          @next_wakeup_check_time = 0
          @properties['lastWakeUpTime'] = updates["data.lastWakeup"]["value"]
          event = AliveEvent.new(device_id, @properties['lastWakeUpTime'])
        end
        @properties['lastSleepTime'] = updates["data.lastSleep"]["value"] if names.include? 'data.lastSleep'
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
      return nil if @dead
      current_time = Time.now.to_i
      if(current_time >= @next_wakeup_check_time)
        wakeup_interval = @properties['wakeUpInterval']
        last_sleep_time = @properties['lastSleepTime']
        unless(wakeup_interval && last_sleep_time)
          return
        end
        estimated_wakeup_time = last_sleep_time + (wakeup_interval * (1 + @wakeup_missed_count) * 1.1)
        if(current_time > estimated_wakeup_time)
          @wakeup_missed_count = (current_time - last_sleep_time) / wakeup_interval
          if(@wakeup_missed_count < MAXIMUM_WAKEUP_MISSED_COUNT)
            @next_wakeup_check_time = estimated_wakeup_time
            return NotAliveEvent.new(device_id, current_time - last_sleep_time - wakeup_interval)
          elsif(@wakeup_missed_count >= MAXIMUM_WAKEUP_MISSED_COUNT)
            @dead = true
            return DeadEvent.new(device_id)
          end
        else
          @next_wakeup_check_time = estimated_wakeup_time
          nil
        end
      end
    end
  end
end
