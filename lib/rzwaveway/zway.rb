require 'singleton'

require 'faraday'
require 'log4r'
require 'json'

module RZWaveWay
  class ZWay
    include Singleton
    include Log4r

    attr_reader :log

    def initialize
      @devices = {}
      @event_handlers = {}
      @log = default_logger
      @update_time = '0'
    end

    def execute(device_id, command_class, command_class_function, argument = nil)
      raise "No device with id '#{device_id}'" unless @devices.has_key?(device_id)
      raise "Device with id '#{device_id}' does not support command class '#{command_class}'" unless @devices[device_id].support_commandclass?(command_class)
      function_name = command_class_function.to_s
      run_zway_function(device_id, command_class, function_name, argument)
    end

    def find_device(device_id)
      @devices[device_id.to_i]
    end

    def find_extension(name, device_id)
      device = find_device(device_id)
      raise ArgumentError, "No device with id '#{device_id}'" unless device
      clazz = qualified_const_get "RZWaveWay::Extensions::#{name}"
      clazz.new(device)
    end

    def inspect
      content = to_s
      @devices.values.each {|device| content << "\n#{device}"}
      content
    end

    def run_zway_no_operation device_id
      run_zway "devices[#{device_id}].SendNoOperation()"
    end

    def setup(options, *adapter_params)
      hostname = options[:hostname] || '127.0.0.1'
      port = options[:port] || 8083
      username = options[:username] || 'admin'
      password = options[:password] || 'changeme'
      adapter_params = :httpclient if adapter_params.compact.empty?
      @base_uri="http://#{hostname}:#{port}"
      @connection = Faraday.new do |connection|
        connection.basic_auth username, password
        connection.adapter *adapter_params
      end
      @log = options[:logger] if options.has_key? :logger
      @polling_interval = options[:polling_interval] || 10 # seconds
    end

    def start
      @stop = false
      @thread = Thread.new do
        until @stop do
          begin
            updates = get_zway_data_tree_updates
            if updates.has_key? 'devices'
              create_devices updates
            else
              process updates
            end
            sleep @polling_interval
          rescue Exception => ex
            log.warn ex.message
            log.warn ex.backtrace
          end
        end
      end
    end

    def stop
      @stop = true
      @thread.join
    end

    def on_event(event, &listener)
      @event_handlers[event] = listener
    end

    def to_s
      "ZWay at '#{@base_uri}' with #{@devices.count} device(s)"
    end

    private

    DATA_TREE_BASE_PATH='/ZWaveAPI/Data/'
    RUN_BASE_PATH='/ZWaveAPI/Run/'

    def create_device(device_id, device_data_tree)
      @devices[device_id] = ZWaveDevice.new(device_id, device_data_tree)
    end

    def create_devices(updates)
      events = []
      updates['devices'].each do |device_id,device_data_tree|
        next if device_id == '1'
        device = create_device(device_id.to_i, device_data_tree)
        events << DeviceDiscoveredEvent.new(device_id: device.id)
      end
      deliver_to_handlers events
    end

    def create_status_event_for(device)
      log.debug "Device '#{device.name}' is now #{device.status}"
      DeviceStatusUpdatedEvent.new(device_id: device.id, time: device.last_contact_time)
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
          log.error("#{response.status} - #{response.reason_phrase}" )
        end
      rescue StandardError => e
        log.error("Failed to communicate with ZWay HTTP server: #{e}")
      end
      results
    end

    def process(updates)
      updates_per_device = group_per_device updates

      events = []
      @devices.each do |device_id, device|
        previous_status = device.status

        if updates_per_device.has_key? device_id
          device_updates = updates_per_device[device_id]
          device.process(device_updates) do |event|
            events << event
          end
        end

        if previous_status != device.update_status
          events << create_status_event_for(device)
        end
      end
      deliver_to_handlers(events)
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

    def run_zway command_path
      begin
        uri = URI.encode(@base_uri + RUN_BASE_PATH + command_path, '[]')
        response = @connection.get(uri)
        unless response.success?
          log.error("run_zway() failed with status: #{response.status}")
          log.error(response.body)
        end
      rescue StandardError => e
        log.error("Failed to communicate with ZWay HTTP server: #{e}")
        log.error(e.backtrace)
      end
    end
  end
end
