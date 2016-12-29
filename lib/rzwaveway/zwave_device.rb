require 'json'

module RZWaveWay
  class ZWaveDevice
    include CommandClasses
    include Logger

    attr_reader :name
    attr_reader :id
    attr_reader :last_contact_time
    attr_accessor :contact_frequency
    attr_reader :status

    def initialize(id, data)
      @id = id
      initialize_from data
      update_status
      save
      log.info "Created ZWaveDevice with name='#{name}' (id='#{id}')"
    end

    def contacts_controller_periodically?
      support_commandclass? CommandClass::WAKEUP
    end

    def next_contact_time
      @last_contact_time + (@contact_frequency * (1 + @missed_contact_count) * 1.1)
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
      update_status
      events
    end

    def notify_contacted(time)
      if time.to_i > @last_contact_time
        @last_contact_time = time.to_i
        @missed_contact_count = 0
        true
      end
    end

    def add_property(property)
      property[:read_only] = true unless property.has_key? :read_only
      @properties[property[:name]] = property
    end

    def get_property(name)
      [
        @properties[name][:value],
        @properties[name][:update_time]
      ]
    end

    def properties
      @properties.values.reject { |property| property[:internal] }
    end

    def save
      @previous_status = @status
    end

    def status_changed?
      @previous_status != @status
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
      @last_contact_time = find('data.lastReceived.updateTime', data)
      @missed_contact_count = 0
      @contact_frequency = 0
      @properties = {}
      @previous_status = @status = :dead
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

    def process_device_data(data)
      data.each do | key, value |
        case key
        when /^(?:data.)?isFailed/
          @is_failed = value['value']
        when /^(?:data.)?lastReceived/
          notify_contacted(value['updateTime'])
        end
      end
    end

    def update_status(time = Time.now)
      time = time.to_i
      @previous_status = @status

      if contacts_controller_periodically?
        delta = time - next_contact_time
        if delta > 0
          count = ((time - @last_contact_time) / @contact_frequency).to_i
          if count > MAXIMUM_MISSED_CONTACT
            @status = :dead
          elsif count > @missed_contact_count
            @missed_contact_count = count
            @status = :not_alive
          elsif count == 0
            @status = :alive
          end
        else
          @status = :alive
        end
      else
        @status = @is_failed ? :dead : :alive
      end
    end
  end
end
