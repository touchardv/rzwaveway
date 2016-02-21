require 'json'

module RZWaveWay
  class ZWaveDevice
    include CommandClass
    include CommandClasses
    include Logger

    attr_reader :name
    attr_reader :id
    attr_reader :last_contact_time
    attr_accessor :contact_frequency

    def initialize(id, data)
      @id = id
      initialize_from data
      log.info "Created ZWaveDevice with name='#{name}' (id='#{id}')"
    end

    def contacts_controller_periodically?
      support_commandclass? CommandClass::WAKEUP
    end

    def next_contact_time
      @last_contact_time + (@contact_frequency * (1 + @missed_contact_count) * 1.1)
    end

    def to_json
      attributes = {
        name: @name,
        deviceId: @id,
        # TODO remove these obsolete attributes (kept for backward compatibility)
        lastSleepTime: @last_contact_time,
        lastWakeUpTime: @last_contact_time,
        wakeUpInterval: @contact_frequency,
        # ---
        # 'lastContactTime' => @last_contact_time,
        # 'contactFrequency' => @contact_frequency,
        properties: @properties
      }
      attributes.to_json
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
      process_device_data(updates, events)
      events
    end

    def process_alive_check
      return if @dead
      if @contact_frequency > 0
        current_time = Time.now.to_i
        delta = current_time - next_contact_time
        if delta > 0
          count = ((current_time - @last_contact_time) / @contact_frequency).to_i
          if count > MAXIMUM_MISSED_CONTACT
            @dead = true
            DeadEvent.new(@id)
          elsif count > @missed_contact_count
            @missed_contact_count = count
            NotAliveEvent.new(@id, delta, count)
          end
        end
      end
    end

    def notify_contacted(time)
      if time.to_i > @last_contact_time
        @dead = false
        @last_contact_time = time.to_i
        @missed_contact_count = 0
        true
      end
    end

    def add_property(options)
      name = options.delete(:name)
      read_only = options.delete(:read_only) || true
      @properties[name] = options
    end

    def get_property(name)
      [ @properties[name][:value], @properties[name][:update_time] ]
    end

    def update_property(name, value, update_time)
      if @properties.has_key?(name)
        property = @properties[name]
        if property[:value] != value || property[:update_time] < update_time
          property[:value] = value
          property[:update_time] = update_time
          true
        end
      end
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
      @name = find('data.givenName.value', data)
      last_contact_times = [
        find('data.lastReceived.updateTime', data),
        find('data.lastSend.updateTime', data)
      ]
      @last_contact_time = last_contact_times.max

      @dead = false
      @missed_contact_count = 0
      @contact_frequency = 0
      @properties = {}
      @command_classes = create_commandclasses_from data
    end

    def group_per_commandclass updates
      other_updates = {}
      updates_per_commandclass = {}
      updates.each do | key, value |
        match_data = key.match(/\Ainstances.0.commandClasses.(\d+)./)
        if match_data
          command_class = match_data[1].to_i
          updates_per_commandclass[command_class] = {} unless updates_per_commandclass.has_key?(command_class)
          updates_per_commandclass[command_class][match_data.post_match] = value
        else
          other_updates[key] = value
        end
      end
      updates.clear
      updates.merge!(other_updates)
      updates_per_commandclass
    end

    def process_device_data(updates, events)
      times = []
      updates.each do | key, value |
        if key == 'data.lastReceived' || key == 'data.lastSend'
          times << value['updateTime']
        end
      end
      time = times.max
      events << AliveEvent.new(@id, time) if notify_contacted(time)
    end
  end
end
