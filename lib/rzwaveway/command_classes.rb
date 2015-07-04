require 'singleton'

require_relative 'command_class'
require_relative 'command_classes/battery'
require_relative 'command_classes/switch_binary'
require_relative 'command_classes/switch_multi_level'
require_relative 'command_classes/sensor_binary'
require_relative 'command_classes/wake_up'

module RZWaveWay
  module CommandClasses
    class Dummy
      include Singleton

      def initialize
      end

      def process(updates, device)
      end
    end

    class Factory
      include Singleton
      include CommandClass

      def instantiate(id, data, device)
        if CLASSES.has_key? id
          return CLASSES[id].new(data, device)
        else
          return CommandClasses::Dummy.instance
        end
      end

      private

      CLASSES = {
        SWITCH_BINARY => CommandClasses::SwitchBinary,
        SWITCH_MULTI_LEVEL => CommandClasses::SwitchMultiLevel,
        SENSOR_BINARY => CommandClasses::SensorBinary,
        WAKEUP => CommandClasses::WakeUp,
        BATTERY => CommandClasses::Battery
      }
    end
  end
end
