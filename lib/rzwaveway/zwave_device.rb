module RZWaveWay
  class ZWaveDevice
    include CommandClasses
    include Logger
    include PropertiesCache

    attr_reader :id
    attr_reader :last_contact_time

    def initialize(id, data)
      @id = id
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
      if @last_contact_time_changed
        events << AliveEvent.new(device_id: @id, time: last_contact_time)
        @last_contact_time_changed = false
      end
      save_changes
      events
    end

    def notify_contacted(time)
      if time > last_contact_time
        @last_contact_time = time
        @last_contact_time_changed = true
      end
    end

    def state
      hash = to_hash
      @command_classes.values.each_with_object(hash) {|cc, hash| hash.merge!(cc.to_hash)}
    end

    def refresh
      @command_classes.values.each do |command_class|
        command_class.refresh if command_class.respond_to? :refresh
      end
    end

    def save_changes
      save_properties
      @command_classes.values.each {|cc| cc.save_properties}
    end

    private

    MAXIMUM_MISSED_CONTACT = 10

    def create_commandclasses_from data
      cc_classes = {}
      data['instances']['0']['commandClasses'].each do |id, sub_tree|
        cc_id = id.to_i
        cc_class = CommandClasses::Factory.instance.instantiate(cc_id, self)
        cc_class.build_from(sub_tree)
        cc_classes[cc_id] = cc_class
        cc_class_name = cc_class.class.name.split('::').last
        (class << self; self end).send(:define_method, cc_class_name) { cc_class } unless cc_class_name == 'Dummy'
      end
      cc_classes
    end

    def initialize_from data
      define_property(:name, 'data.givenName', true, data)
      define_property(:is_failed, 'data.isFailed', true, data)
      @last_contact_time = find('data.lastReceived.updateTime', data)
      @last_contact_time_changed = false

      @command_classes = create_commandclasses_from data
      save_changes
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
          properties[:is_failed].update(value['value'], value['updateTime'])
        when /^(?:data.)?lastReceived/
          notify_contacted(value['updateTime'])
        end
      end
    end
  end
end
