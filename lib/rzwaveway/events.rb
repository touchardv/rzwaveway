require 'ostruct'

module RZWaveWay
  class Event < OpenStruct
    def initialize(hash)
      raise ArgumentError, 'Hash can not be nil' unless hash
      raise ArgumentError, 'Missing device_id' unless hash.has_key? :device_id
      hash[:time] = Time.now.to_i unless hash.has_key? :time

      super(hash)
    end
  end

  class AlarmEvent < Event ; end

  class AliveDevice < Event ; end
  class InactiveDevice < Event ; end
  class DeadDevice < Event ; end

  class DeviceUpdatedEvent < Event ; end

  class LevelEvent < Event ; end

  class MultiLevelEvent < LevelEvent ; end

  class BatteryValueEvent < Event ; end
end
