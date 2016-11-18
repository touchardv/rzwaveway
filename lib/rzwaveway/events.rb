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

  class AlarmEvent < OpenStruct ; end

  class AliveEvent < OpenStruct ; end

  class NotAliveEvent < OpenStruct ; end

  class DeadEvent < OpenStruct ; end

  class LevelEvent < OpenStruct ; end

  class MultiLevelEvent < LevelEvent ; end

  class BatteryValueEvent < OpenStruct ; end
end
