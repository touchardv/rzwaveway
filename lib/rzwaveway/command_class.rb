module RZWaveWay
  class CommandClass
    include Logger
    include PropertiesCache

    BASIC = 32
    SWITCH_BINARY = 37
    SWITCH_MULTI_LEVEL = 38
    SENSOR_BINARY = 48
    SENSOR_MULTI_LEVEL = 49
    CONFIGURATION = 112
    ALARM = 113
    NOTIFICATION = ALARM
    MANUFACTURER_SPECIFIC = 114
    BATTERY = 128
    WAKEUP = 132
    ASSOCIATION = 133
    VERSION = 134
    ALARM_SENSOR = 156

    attr_reader :device

    def initialize(device)
      @device = device
    end

    def build_from(data)
    end
  end
end
