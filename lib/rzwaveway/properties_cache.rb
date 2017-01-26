module RZWaveWay
  module PropertiesCache
    def save_properties
      properties.values.each {|property| property.save}
    end

    def to_hash
      properties.each_with_object({}) {|property, hash| hash[property[0]] = property[1].to_hash}
    end

    private

    def define_property(property_name, key, read_only, data)
      options = {
        value: find("#{key}.value", data),
        update_time: find("#{key}.updateTime", data),
        read_only: read_only
      }
      property = Property.new(options)
      (class << self; self end).send(:define_method, property_name) { property.value }
      properties[property_name] = property
    end

    def find(name, data)
      parts = name.split '.'
      result = data
      parts.each do | part |
        raise "Could not find part '#{part}' in '#{name}'" unless result.has_key? part
        result = result[part]
      end
      result
    end

    def properties
      @properties ||= {}
    end
  end
end
