require 'singleton'

require_relative 'command_class'
require_relative 'command_classes/alarm'
require_relative 'command_classes/battery'
require_relative 'command_classes/switch_binary'
require_relative 'command_classes/switch_multi_level'
require_relative 'command_classes/sensor_binary'
require_relative 'command_classes/wake_up'

module RZWaveWay
  module CommandClasses
    class Dummy
      include Singleton

      def process(updates)
      end
    end

    class Factory
      include Singleton

      def instantiate(id, data, device)
        if CLASSES.has_key? id
          return CLASSES[id].new(data, device)
        else
          return CommandClasses::Dummy.instance
        end
      end

      private

      CLASSES = {
        CommandClass::SWITCH_BINARY => CommandClasses::SwitchBinary,
        CommandClass::SWITCH_MULTI_LEVEL => CommandClasses::SwitchMultiLevel,
        CommandClass::SENSOR_BINARY => CommandClasses::SensorBinary,
        CommandClass::WAKEUP => CommandClasses::WakeUp,
        CommandClass::ALARM => CommandClasses::Alarm,
        CommandClass::BATTERY => CommandClasses::Battery
      }
    end
  end
end
