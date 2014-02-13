require 'json'

module RZWaveWay
  class ZWaveDevice
    include CommandClasses

    attr_reader :id

    def initialize(id, data)
      @id = id
      @command_classes = create_commandclasses_from data
      $log.info "Created ZWaveDevice with id='#{id}'"
    end

    def create_commandclasses_from data
      cc_classes = {}
      data['instances']['0']['commandClasses'].each do |cc_id, sub_tree|
        cc_classes[cc_id.to_i] = CommandClass.new(cc_id.to_i, sub_tree)
      end
      cc_classes
    end

    def build_json
      properties = {'deviceId' => @id}
      @command_classes.each do |cc_id, cc|
        properties.merge!(cc.properties)
      end
      properties.to_json
    end

    def support_commandclass? command_class
      @command_classes.has_key? command_class
    end

    def process updates
      events = []
      updates_per_commandclass =  group_per_commandclass updates
      updates_per_commandclass.each do |cc, values|
        if @command_classes.has_key? cc
          event = @command_classes[cc].process(values, @id)
          events << event if event
        else
          $log.warn "Could not find command class: '#{cc}'"
        end
      end
      events
    end

    def process_alive_check
      if(support_commandclass? WAKEUP)
        return @command_classes[WAKEUP].process_alive_check(@id)
      end
    end

    private

    def group_per_commandclass updates
      updates_per_commandclass = Hash.new({})
      updates.each do | key, value |
        match_data = key.match(/\Ainstances.0.commandClasses.(\d+)./)
        if match_data
          command_class = match_data[1].to_i
          cc_updates = updates_per_commandclass[command_class]
          cc_updates[match_data.post_match] = value
          updates_per_commandclass[command_class] = cc_updates
        else
          $log.warn "? #{key}" unless key.match(/\Adata./)
        end
      end
      updates_per_commandclass
    end
  end
end