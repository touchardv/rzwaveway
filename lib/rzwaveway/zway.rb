require 'uri'
require 'log4r'
require 'net/http'
require 'json'

module RZWaveWay
  module ZWay
    extend self
    include Log4r

    def self.init hostname
      $log = Logger.new 'RZWaveWay'
      outputter = Outputter.stdout
      outputter.formatter = PatternFormatter.new(:pattern => "[%l] %d - %m")
      $log.outputters = Outputter.stdout
      @devices = {}
      @update_time = "0"
      @uri = URI::HTTP.build({:host => hostname, :port => 8083})
      @event_handlers = {}
    end

    def get_devices
      @uri.path = "/ZWaveAPI/Data/#{@update_time}"
      response = http_post_request
      if response.code == "200"
        results = JSON.parse response.body
        @update_time = results["updateTime"]
        results["devices"].each do |device |
          device_id = device[0].to_i
          @devices[device_id] = ZWaveDevice.new(device_id, device[1]) if device_id > 1
        end
        @devices
      else
        $log.error response.code
        return {}
      end
    end

    def process_events
      events = []
      updates = get_updates
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

    def get_updates
      @uri.path = "/ZWaveAPI/Data/#{@update_time}"
      response = http_post_request
      if response.is_a?(Net::HTTPSuccess)
        results = JSON.parse response.body
        @update_time = results.delete("updateTime")
        return results
      else
        $log.error response.code
        return {}
      end
    end

    def group_per_device updates
      updates_per_device = Hash.new({})
      updates.each do | key, value |
        match_data = key.match(/\Adevices\.(\d+)\./)
        if match_data
          device_id = match_data[1].to_i
          device_updates = updates_per_device[device_id]
          device_updates[match_data.post_match] = value
          updates_per_device[device_id] = device_updates
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
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = false

      request = Net::HTTP::Post.new(@uri.path)
      http.request(request)
    end

    def on_event (event, &listener)
      @event_handlers[event] = listener
    end
  end
end