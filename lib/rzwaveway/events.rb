module RZWaveWay
  class AliveEvent
    attr_reader :device_id
    attr_reader :time

    def initialize device_id, time
      @device_id = device_id
      @time = time
    end
  end

  class NotAliveEvent
    attr_reader :device_id
    attr_reader :time_delay

    def initialize(device_id, time_delay)
      @device_id = device_id
      @time_delay = time_delay
    end
  end

  class DeadEvent
    attr_reader :device_id

    def initialize(device_id)
      @device_id = device_id
    end
  end

  class LevelEvent
    attr_reader :device_id
    attr_reader :time
    attr_reader :level

    def initialize(device_id, time, level)
      @device_id = device_id
      @time = time
      @level = level
    end
  end

  class BatteryValueEvent
    attr_reader :device_id
    attr_reader :time
    attr_reader :value

    def initialize(device_id, time, value)
      @device_id = device_id
      @time = time
      @value = value
    end
  end

  class SmokeEvent
    attr_reader :device_id
    attr_reader :time
  end

  class HighTemperatureEvent
    attr_reader :device_id
    attr_reader :time
  end

  class TamperingEvent
    attr_reader :device_id
    attr_reader :time
  end
end
