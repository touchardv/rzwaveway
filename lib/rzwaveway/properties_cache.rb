module RZWaveWay
  module PropertiesCache
    def define_property(name, key, read_only, data)
      raise ArgumentError, "Property already defined: #{name}" if properties.has_key? name

      options = {
        value: find("#{key}.value", data),
        update_time: find("#{key}.updateTime", data),
        read_only: read_only
      }
      property = Property.new(options)
      properties[name] = property
      (class << self; self end).send(:define_method, name) { property.value }
    end

    def properties
      @properties ||= {}
    end

    def properties_changed?
      properties.values.any? {|property| property.changed?}
    end

    def save_properties
      properties.values.each {|property| property.save}
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
