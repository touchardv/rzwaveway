require 'json'

module RZWaveWay
  class ZWaveDevice
    include CommandClasses
    include Logger

    attr_reader :name
    attr_reader :id

    def initialize(id, data)
      @id = id
      @properties = {}
      initialize_from data
      log.info "Created ZWaveDevice with name='#{name}' (id='#{id}')"
    end

    def contacts_controller_periodically?
      support_commandclass? CommandClass::WAKEUP
    end

    def support_commandclass?(command_class_id)
      @command_classes.has_key? command_class_id
    end

    def process updates
      events = []
      updates_per_commandclass = group_per_commandclass updates
      updates_per_commandclass.each do |cc, values|
        if @command_classes.has_key? cc
          event = @command_classes[cc].process(values)
          events << event if event
        else
          log.warn "Could not find command class: '#{cc}'"
        end
      end
      process_device_data(updates)
      if @last_contact_time.changed?
        events << AliveEvent.new(device_id: @id, time: @last_contact_time.value)
      end
      save_changes
      events
    end

    def contact_failure?
      @is_failed.value
    end

    def last_contact_time
      @last_contact_time.value
    end

    def notify_contacted(time)
      @last_contact_time.update(time.to_i, time.to_i)
    end

    def add_property(name, property)
      self.class.send(:define_method, name) { property }
      @properties[name] = property
    end

    def properties
      @properties.each_with_object({}) do |property, values|
        values[property[0]] = property[1].to_hash
      end
    end

    def refresh
      @command_classes.values.each do |command_class|
        command_class.refresh if command_class.respond_to? :refresh
      end
    end

    def save_changes
      @properties.values.each {|property| property.save}
      @is_failed.save
      @last_contact_time.save
    end

    private

    MAXIMUM_MISSED_CONTACT = 10

    def create_commandclasses_from data
      cc_classes = {}
      data['instances']['0']['commandClasses'].each do |id, sub_tree|
        cc_id = id.to_i
        cc_class = CommandClasses::Factory.instance.instantiate(cc_id, sub_tree, self)
        cc_classes[cc_id] = cc_class
        cc_class_name = cc_class.class.name.split('::').last
        (class << self; self end).send(:define_method, cc_class_name) { cc_class } unless cc_class_name == 'Dummy'
      end
      cc_classes
    end

    def initialize_from data
      last_received = find('data.lastReceived.updateTime', data)

      @name = find('data.givenName.value', data)
      @is_failed = Property.new(value: false, update_time: 0)
      @last_contact_time = Property.new(value: last_received, update_time: last_received)
      @command_classes = create_commandclasses_from data

      process_device_data(data['data'])
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

    def group_per_commandclass updates
      other_updates = {}
      updates_per_commandclass = {}
      updates.each do | key, value |
        match_data = key.match(/\Ainstances.0.commandClasses.(\d+)./)
        if match_data
          command_class = match_data[1].to_i
          updates_per_commandclass[command_class] ||= {}
          updates_per_commandclass[command_class][match_data.post_match] = value
        else
          other_updates[key] = value
        end
      end
      updates.clear
      updates.merge!(other_updates)
      updates_per_commandclass
    end

    def process_device_data(data)
      data.each do | key, value |
        case key
        when /^(?:data.)?isFailed/
          @is_failed.update(value['value'], value['updateTime'])
        when /^(?:data.)?lastReceived/
          notify_contacted(value['updateTime'])
        end
      end
    end
  end
end
