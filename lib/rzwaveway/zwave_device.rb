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

    def support_commandclass?(command_class_id)
      @command_classes.has_key? command_class_id
    end

    def process(updates)
      updates_per_commandclass = group_per_commandclass updates
      updates_per_commandclass.each do |cc, values|
        if @command_classes.has_key? cc
          @command_classes[cc].process(values) do |event|
            yield event if event
          end
        else
          log.warn "Could not find command class: '#{cc}'"
        end
      end
      process_device_data(updates)
      save_changes
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

    def state
      hash = to_hash
      @command_classes.values.each_with_object(hash) {|cc, hash| hash.merge!(cc.to_hash)}
    end

    def update_status
      @status = if contacts_controller_periodically?
        if self.WakeUp.on_time?
          :alive
        elsif self.WakeUp.missed_contact_count < 10 # times
          :inactive
        else
          :dead
        end
      else
        if elapsed_minutes_since_last_contact > 60 # minutes
          :dead
        elsif elapsed_minutes_since_last_contact > 5  # minutes
          :inactive
        else
          :alive
        end
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
        (class << self; self end).send(:define_method, cc_class_name) { cc_class } unless cc_class_name == 'Dummy'
      end
    end

    def elapsed_minutes_since_last_contact(time = Time.now)
      (time.to_i - last_contact_time) / 60
    end

    def initialize_from data
      define_property(:name, 'data.givenName', true, data)
      define_property(:is_failed, 'data.isFailed', true, data)
      
      last_received = find('data.lastReceived.updateTime', data)
      last_send = find('data.lastSend.updateTime', data)
      @last_contact_time = last_received > last_send ? last_received : last_send

      create_commandclasses_from data
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
        when /^(?:data.)?[lastSend|lastReceived]/
          notify_contacted(value['updateTime'])
        end
      end
    end

    def save_changes
      save_properties
      @command_classes.values.each {|cc| cc.save_properties}
    end
  end
end
