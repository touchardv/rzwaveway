require 'httpclient'
require 'log4r'
require 'json'

module RZWaveWay
  module ZWay
    extend self
    include Log4r

    BASE_PATH='/ZWaveAPI/Data/'

    def self.init hostname
      $log = Logger.new 'RZWaveWay'
      outputter = Outputter.stdout
      outputter.formatter = PatternFormatter.new(:pattern => "[%l] %d - %m")
      $log.outputters = Outputter.stdout
      @devices = {}
      @update_time = "0"
      @event_handlers = {}
      @http_client = HTTPClient.new
      @base_uri="http://#{hostname}:8083"
    end

    def get_devices
      results = http_post_request
      if(results.has_key?("devices"))
        results["devices"].each do |device_id,device_data_tree|
          device_id = device_id.to_i
          @devices[device_id] = ZWaveDevice.new(device_id, device_data_tree) if device_id > 1
        end
      end
      @devices
    end

    def process_events
      events = []
      updates = http_post_request
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
          $log.warn "no handler for #{event.class}"
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
          $log.warn "? #{key}"
        end
      end
      updates_per_device
    end

    def check_not_alive_devices
      events = []
      @devices.values.each do |device|
        event = device.process_alive_check
        events << event if event 
      end
      events
    end

    def http_post_request
      results = {}
      url = @base_uri + BASE_PATH + "#{@update_time}"
      begin
        response = @http_client.post(url)
        if response.ok?
          results = JSON.parse response.body
          @update_time = results.delete("updateTime")
        else
          $log.error(response.reason)
        end
      rescue StandardError => e
        $log.error("Failed to communicate with ZWay HTTP server: #{e}")
      end
      results
    end

    def on_event (event, &listener)
      @event_handlers[event] = listener
    end
  end
end