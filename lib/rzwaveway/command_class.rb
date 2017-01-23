module RZWaveWay
  class CommandClass
    include Logger

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
      @properties = {}
    end

    def build_from(data)
      nil
    end

    def define_property(property_name, key, read_only, data)
      options = {
        value: find("#{key}.value", data),
        update_time: find("#{key}.updateTime", data),
        read_only: read_only
      }
      property = Property.new(options)
      (class << self; self end).send(:define_method, property_name) { property.value }
      @properties[property_name] = property
    end

    def to_hash
      @properties.each_with_object({}) {|property, hash| hash[property[0]] = property[1].to_hash}
    end

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
