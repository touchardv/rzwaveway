require 'ostruct'

module RZWaveWay
  class AlarmEvent < OpenStruct ; end

  class AliveEvent < OpenStruct ; end

  class NotAliveEvent < OpenStruct ; end

  class DeadEvent < OpenStruct ; end

  class LevelEvent < OpenStruct ; end

  class MultiLevelEvent < LevelEvent ; end

  class BatteryValueEvent < OpenStruct ; end
end
