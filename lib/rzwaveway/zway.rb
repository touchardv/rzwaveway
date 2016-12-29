require 'singleton'

require 'faraday'
require 'log4r'
require 'json'

module RZWaveWay
  class ZWay
    include Singleton
    include Log4r

    attr_reader :devices
    attr_reader :log

    def initialize
      @log = default_logger
    end

    def execute(device_id, command_class, command_class_function, argument = nil)
      raise "No device with id '#{device_id}'" unless @devices.has_key?(device_id)
      raise "Device with id '#{device_id}' does not support command class '#{command_class}'" unless @devices[device_id].support_commandclass?(command_class)
      function_name = command_class_function.to_s
      run_zway_function(device_id, command_class, function_name, argument)
    end

    def find_extension(name, device_id)
      device = @devices[device_id.to_i]
      raise ArgumentError, "No device with id '#{device_id}'" unless device
      clazz = qualified_const_get "RZWaveWay::Extensions::#{name}"
      clazz.new(device)
    end

    def setup(options, *adapter_params)
      hostname = options[:hostname] || '127.0.0.1'
      port = options[:port] || 8083
      adapter_params = :httpclient if adapter_params.compact.empty?
      @base_uri="http://#{hostname}:#{port}"
      @connection = Faraday.new {|faraday| faraday.adapter *adapter_params}
      @log = options[:logger] if options.has_key? :logger
    end

    def start
      @devices = {}
      @event_handlers = {}
      @update_time = '0'
      loop do
        results = get_zway_data_tree_updates
        if results.has_key?('devices')
          results['devices'].each {|device_id,device_data_tree| create_device(device_id.to_i, device_data_tree)}
          break
        else
          sleep 1.0
          log.warn 'No devices found at start-up, retrying'
        end
      end
    end

    def on_event(event, &listener)
      @event_handlers[event] = listener
    end

    def process_events
      updates = get_zway_data_tree_updates
      events = devices_process updates
      check_devices_status_changes(events)
      deliver_to_handlers(events)
    end

    private

    DATA_TREE_BASE_PATH='/ZWaveAPI/Data/'
    RUN_BASE_PATH='/ZWaveAPI/Run/'

    def create_device(device_id, device_data_tree)
      if device_id > 1
        @devices[device_id] = ZWaveDevice.new(device_id, device_data_tree)
      end
    end

    def check_devices_status_changes(events)
      @devices.each do |device_id, device|
        if device.status_changed?
          events << case device.status
          when :alive
            AliveEvent.new(device_id: device_id, time: device.last_contact_time)
          when :not_alive
            NotAliveEvent.new(device_id: device_id)
          when :dead
            DeadEvent.new(device_id: device_id)
          else
            raise "Unknown device status: #{device.status}"
          end
        end
        device.save
      end
    end

    def default_logger
      Log4r::Logger.new 'RZWaveWay'
    end

    def deliver_to_handlers events
      events.each do |event|
        handler = @event_handlers[event.class]
        if handler
          handler.call(event)
        else
          log.warn "No event handler for #{event.class}"
        end
      end
    end

    def devices_process updates
      events = []
      updates_per_device = group_per_device updates
      updates_per_device.each do | id, updates |
        if @devices[id]
          device_events = @devices[id].process updates
          events += device_events unless device_events.empty?
        else
          log.warn "Could not find device with id '#{id}'"
        end
      end
      events
    end

    def group_per_device updates
      updates_per_device = {}
      updates.each do | key, value |
        match_data = key.match(/\Adevices\.(\d+)\./)
        if match_data
          device_id = match_data[1].to_i
          updates_per_device[device_id] = {} unless(updates_per_device.has_key?(device_id))
          updates_per_device[device_id][match_data.post_match] = value
        else
          log.debug "No device group match for key='#{key}'"
        end
      end
      updates_per_device
    end

    def get_zway_data_tree_updates
      results = {}
      url = @base_uri + DATA_TREE_BASE_PATH + "#{@update_time}"
      begin
        response = @connection.get(url)
        if response.success?
          results = JSON.parse response.body
          @update_time = results.delete('updateTime')
        else
          log.error(response.reason)
        end
      rescue StandardError => e
        log.error("Failed to communicate with ZWay HTTP server: #{e}")
      end
      results
    end

    def qualified_const_get(str)
      path = str.to_s.split('::')
      from_root = path[0].empty?
      if from_root
        from_root = []
        path = path[1..-1]
      else
        start_ns = ((Class === self)||(Module === self)) ? self : self.class
        from_root = start_ns.to_s.split('::')
      end
      until from_root.empty?
        begin
          return (from_root+path).inject(Object) { |ns,name| ns.const_get(name) }
        rescue NameError
          from_root.delete_at(-1)
        end
      end
      path.inject(Object) { |ns,name| ns.const_get(name) }
    end

    def run_zway_function(device_id, command_class, function_name, argument)
      command_path = "devices[#{device_id}].instances[0].commandClasses[#{command_class}]."
      if argument
        command_path += "#{function_name}(#{argument})"
      else
        command_path += "#{function_name}()"
      end
      run_zway command_path
    end

    def run_zway_no_operation device_id
      run_zway "devices[#{device_id}].SendNoOperation()"
    end

    def run_zway command_path
      begin
        uri = URI.encode(@base_uri + RUN_BASE_PATH + command_path, '[]')
        response = @connection.get(uri)
        unless response.success?
          log.error(response.status)
          log.error(response.body)
        end
      rescue StandardError => e
        log.error("Failed to communicate with ZWay HTTP server: #{e}")
        log.error(e.backtrace)
      end
    end
  end
end
