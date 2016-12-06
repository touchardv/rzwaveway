module RZWaveWay
  class CommandClass
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

    def initialize(data, device)
      @device = device
      property_mappings.each_pair do |property_name, options|
        property = {
          name: property_name,
          value: find("#{options[:key]}.value", data),
          update_time: find("#{options[:key]}.updateTime", data),
          read_only: (options.has_key?(:read_only) ? options[:read_only] : true),
          internal: (options.has_key?(:internal) ? options[:internal] : false)
        }
        device.add_property(property)
      end
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
