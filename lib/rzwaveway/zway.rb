require 'singleton'

require 'httpclient'
require 'log4r'
require 'json'

module RZWaveWay
  class ZWay
    include Singleton
    include Log4r

    attr_reader :devices

    BASE_PATH='/ZWaveAPI/Data/'

    def initialize
      $log = Logger.new 'RZWaveWay'
      formatter = PatternFormatter.new(:pattern => "[%l] %d - %m")
      outputter = Outputter.stdout
      outputter.formatter = formatter
      outputter.level = Log4r::INFO
      file_outputter = RollingFileOutputter.new('file', filename: 'rzwaveway.log', maxsize: 1048576, trunc: 86400)
      file_outputter.formatter = formatter
      file_outputter.level = Log4r::DEBUG
      $log.outputters = [Outputter.stdout, file_outputter]
    end

    def execute(device_id, command_class, command_class_function, argument = nil)
      raise "No device with id '#{device_id}'" unless @devices.has_key?(device_id)
      raise "Device with id '#{device_id}' does not support command class '#{command_class}'" unless @devices[device_id].support_commandclass?(command_class)
      function_name = command_class_function.to_s
      if argument
        uri = @base_uri + "/ZWaveAPI/Run/devices[#{device_id}].instances[0].commandClasses[#{command_class}].#{function_name}(#{argument})"
      else
        uri = @base_uri + "/ZWaveAPI/Run/devices[#{device_id}].instances[0].commandClasses[#{command_class}].#{function_name}()"
      end
      puts uri
    end

    def setup(hostname)
      @base_uri="http://#{hostname}:8083"
      @http_client = HTTPClient.new
    end

    def start
      @devices = {}
      @event_handlers = {}
      @update_time = '0'
      results = http_get_request
      if(results.has_key?('devices'))
        results['devices'].each do |device_id,device_data_tree|
          device_id = device_id.to_i
          @devices[device_id] = ZWaveDevice.new(device_id, device_data_tree) if device_id > 1
        end
      end
    end

    def on_event(event, &listener)
      @event_handlers[event] = listener
    end

    def process_events
      events = []
      updates = http_get_request
      updates_per_device = group_per_device updates
      updates_per_device.each do | id, updates |
        if @devices[id]
          device_events = @devices[id].process updates
          events += device_events unless device_events.empty?
        else
          $log.warn "Could not find device with id '#{id}'"
        end
      end
      alive_events = check_not_alive_devices
      events += alive_events unless alive_events.empty?
      events.each do |event|
        handler = @event_handlers[event.class]
        if handler
          handler.call(event)
        else
          $log.warn "No event handler for #{event.class}"
        end
      end
      events
    end

    private

    def check_not_alive_devices
      @devices.values.each_with_object([]) do |device, events|
        event = device.process_alive_check
        events << event if event
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
          $log.debug "No device group match for key='#{key}'"
        end
      end
      updates_per_device
    end

    def http_get_request
      results = {}
      url = @base_uri + BASE_PATH + "#{@update_time}"
      begin
        response = @http_client.get(url)
        if response.ok?
          results = JSON.parse response.body
          @update_time = results.delete('updateTime')
        else
          $log.error(response.reason)
        end
      rescue StandardError => e
        $log.error("Failed to communicate with ZWay HTTP server: #{e}")
      end
      results
    end
  end
end
