module RZWaveWay
  module Logger
    def log
      RZWaveWay::ZWay.instance.log
    end
  end
end
