module RZWaveWay
  module CommandClass
    BASIC = 32
    SWITCH_MULTI_LEVEL = 38
    SENSOR_BINARY = 48
    SENSOR_MULTI_LEVEL = 49
    CONFIGURATION = 112
    ALARM = 113
    MANUFACTURER_SPECIFIC = 114
    BATTERY = 128
    WAKEUP = 132
    ASSOCIATION = 133
    VERSION = 134
    ALARM_SENSOR = 156

    private

    def find(name, data)
      parts = name.split '.'
      result = data
      parts.each do | part |
        raise "Could not find part '#{part}' in '#{name}'" unless result.has_key? part
        result = result[part]
      end
      result
    end
  end
end
