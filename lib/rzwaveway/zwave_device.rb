module RZWaveWay
  class ZWaveDevice
    include CommandClasses
    include Logger
    include PropertiesCache

    attr_reader :id
    attr_reader :last_contact_time
    attr_reader :status

    def initialize(id, data)
      @id = id
      @command_classes = {}
      initialize_from data
      update_status
      log.info "Created device with name='#{name}' status=#{status} (id='#{id}')"
    end

    def contact
      RZWaveWay::ZWay.instance.run_zway_no_operation(id)
    end

    def contacts_controller_periodically?
      support_commandclass? CommandClass::WAKEUP
    end

    def inspect
      output = [to_s]
      output += @command_classes.collect {|id, command_class| "#{id} - #{command_class}"}
      output.join "\n"
    end

    def support_commandclass?(command_class_id)
      @command_classes.has_key? command_class_id
    end

    def process(updates)
      updates_per_commandclass = group_per_commandclass updates
      updates_per_commandclass.each do |cc, values|
        if @command_classes.has_key? cc
          begin
            @command_classes[cc].process(values) {|event| yield event}
          rescue Exception => ex
            log.error "ZWaveDevice::process() failed: #{ex.message}"
            log.error ex.backtrace
            log.error values
          end
        else
          log.warn "Could not find command class: '#{cc}'"
        end
      end
      process_device_data(updates)
      if properties_changed?
        yield DeviceUpdatedEvent.new(device_id: id)
        save_properties
      end
    end

    def notify_contacted(time)
      if time > @last_contact_time
        @last_contact_time = time
      end
    end

    def refresh
      @command_classes.values.each do |command_class|
        command_class.refresh if command_class.respond_to? :refresh
      end
    end

    def to_s
      "#{id} (#{name}) - #{status} (#{Time.at(last_contact_time)})"
    end

    def update_status
      @status = if is_failed
        :failed
      else
        :ok
      end
    end

    private

    def create_commandclasses_from data
      data['instances']['0']['commandClasses'].each do |id, sub_tree|
        cc_id = id.to_i
        cc_class = CommandClasses::Factory.instance.instantiate(cc_id, self)
        cc_class.build_from(sub_tree)
        @command_classes[cc_id] = cc_class
        cc_class_name = cc_class.class.name.split('::').last
        (class << self; self end).send(:define_method, cc_class_name) { cc_class } unless cc_class_name == 'Unsupported'
      end
    end

    def initialize_from data
      define_property(:name, 'data.givenName', true, data)
      define_property(:is_failed, 'data.isFailed', true, data)
      define_property(:failure_count, 'data.failureCount', true, data)
      
      @last_contact_time = find('data.lastReceived.updateTime', data)
      notify_contacted(properties[:is_failed].update_time) unless is_failed

      create_commandclasses_from data
      save_properties
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
        when /^(?:data.)?failureCount/
          properties[:failure_count].update(value['value'], value['updateTime'])
        when /^(?:data.)?givenName/
          properties[:name].update(value['value'], value['updateTime'])
        when /^(?:data.)?isFailed/
          properties[:is_failed].update(value['value'], value['updateTime'])
          notify_contacted(value['updateTime']) unless is_failed
        when /^(?:data.)?lastReceived/
          notify_contacted(value['updateTime'])
        end
      end
    end
  end
end
