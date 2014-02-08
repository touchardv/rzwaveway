require 'json'

require_relative 'command_classes'

module RZWaveWay
  class ZWaveDevice
    include CommandClasses

    attr_reader :id

    def initialize(id, data)
      @id = id
      @command_classes = create_commandclasses_from data
      puts "Created ZWaveDevice with id='#{id}'"
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
      if(support_commandclass? SENSOR_BINARY)
        properties.merge!( {
          'level' => @command_classes[SENSOR_BINARY].get_data('data.1.level.value'),
          'lastLevelChangeTime' => @command_classes[SENSOR_BINARY].get_data('data.1.level.updateTime')          
        })
      end
      if(support_commandclass? WAKEUP)
        properties.merge!( {
          'wakeUpInterval' => @command_classes[WAKEUP].get_data('data.interval.value'),
          'lastSleepTime' => @command_classes[WAKEUP].get_data('data.lastSleep.value'),
          'lastWakeUpTime' => @command_classes[WAKEUP].get_data('data.lastWakeup.value')
        })
      end
      if(support_commandclass? BATTERY)
        properties.merge!( {
          'batteryLevel' => @command_classes[BATTERY].get_data('data.last.value')
        })
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
        events << (@command_classes[cc].process(values, @id))
      end
      events
    end

    def group_per_commandclass updates
      updates_per_commandclass = Hash.new { [] }
      updates.each do | key, value |
        match_data = key.match(/\Ainstances.0.commandClasses.(\d+)./)
        if match_data
          command_class = match_data[1].to_i
          cc_updates = updates_per_commandclass[command_class]
          cc_updates << [match_data.post_match, value]
          updates_per_commandclass[command_class] = cc_updates
        else
          puts "? #{key}" unless key.match(/\Adata./)
        end
      end
      updates_per_commandclass
    end

  end
end
