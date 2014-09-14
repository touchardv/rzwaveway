require 'json'

module RZWaveWay
  class ZWaveDevice
    include CommandClasses

    attr_reader :id
    attr_reader :last_contact_time
    attr_accessor :contact_frequency

    def initialize(id, data)
      @dead = false
      @id = id
      @last_contact_time = 0
      @missed_contact_count = 0
      @contact_frequency = 0
      @properties = {}
      @command_classes = create_commandclasses_from data
      $log.info "Created ZWaveDevice with id='#{id}'"
    end

    def create_commandclasses_from(data)
      cc_classes = {}
      data['instances']['0']['commandClasses'].each do |id, sub_tree|
        cc_id = id.to_i
        cc_classes[cc_id] = CommandClasses::Factory.instance.instantiate(cc_id, sub_tree, self)
      end
      cc_classes
    end

    def to_json
      attributes = {
        'deviceId' => @id,
        # TODO remove these obsolete attributes (kept for backward compatibility)
        'lastSleepTime' => @last_contact_time,
        'lastWakeUpTime' => @last_contact_time,
        'wakeUpInterval' => @contact_frequency
        # ---
        # 'lastContactTime' => @last_contact_time,
        # 'contactFrequency' => @contact_frequency,
        # 'properties' => @properties.to_json
      }
      attributes.to_json
    end

    def support_commandclass?(command_class_id)
      @command_classes.has_key? command_class_id
    end

    def process(updates)
      events = process_data(updates)
      updates_per_commandclass =  group_per_commandclass updates
      updates_per_commandclass.each do |cc, values|
        if @command_classes.has_key? cc
          event = @command_classes[cc].process(values, self)
          events << event if event
        else
          $log.warn "Could not find command class: '#{cc}'"
        end
      end
      events
    end

    def process_alive_check
      return if @dead
      if @contact_frequency > 0
        current_time = Time.now.to_i
        next_contact_time = @last_contact_time + (@contact_frequency * (1 + @missed_contact_count) * 1.1)
        if current_time > next_contact_time
          count = ((current_time - @last_contact_time) / @contact_frequency).to_i
          if count > MAXIMUM_MISSED_CONTACT
            @dead = true
            DeadEvent.new(@id)
          elsif count > @missed_contact_count
            @missed_contact_count = count
            NotAliveEvent.new(@id, 0)
          end
        end
      end
    end

    def notify_contacted(time)
      if time.to_i > @last_contact_time
        @dead = false
        @last_contact_time = time.to_i
        @missed_contact_count = 0
      end
    end

    def add_property(name, value, updateTime)
      @properties[name] = [value, updateTime]
    end

    def get_property(name)
      @properties[name].dup
    end

    def update_property(name, value, updateTime)
      if @properties.has_key?(name)
        property = @properties[name]
        if property[0] != value || property[1] < updateTime
          property[0] = value
          property[1] = updateTime
          return true
        end
      end
      return false
    end

    private

    MAXIMUM_MISSED_CONTACT = 10

    def group_per_commandclass(updates)
      updates_per_commandclass = {}
      updates.each do | key, value |
        match_data = key.match(/\Ainstances.0.commandClasses.(\d+)./)
        if match_data
          command_class = match_data[1].to_i
          updates_per_commandclass[command_class] = {} unless updates_per_commandclass.has_key?(command_class)
          updates_per_commandclass[command_class][match_data.post_match] = value
        else
          $log.debug "? #{key}" unless key.match(/\Adata./)
        end
      end
      updates_per_commandclass
    end

    def process_data(updates)
      events = []
      updates.each do | key, value |
        if key == 'data.lastReceived' || key == 'data.lastSend'
          time = value['updateTime']
          notify_contacted(time)
        end
      end
      events
    end
  end
end
