require 'singleton'

require_relative 'command_class'
require_relative 'command_classes/alarm'
require_relative 'command_classes/alarm_sensor'
require_relative 'command_classes/battery'
require_relative 'command_classes/switch_binary'
require_relative 'command_classes/switch_multi_level'
require_relative 'command_classes/sensor_binary'
require_relative 'command_classes/wake_up'

module RZWaveWay
  module CommandClasses
    class Unsupported
      include Singleton

      def build_from(data)
      end

      def process(updates)
      end

      def save_properties
      end

      def to_hash
        {}
      end

      def to_s
        'Unsupported'
      end
    end

    class Factory
      include Singleton

      def instantiate(id, device)
        if CLASSES.has_key? id
          CLASSES[id].new(device)
        else
          CommandClasses::Unsupported.instance
        end
      end

      private

      CLASSES = {
        CommandClass::SWITCH_BINARY => CommandClasses::SwitchBinary,
        CommandClass::SWITCH_MULTI_LEVEL => CommandClasses::SwitchMultiLevel,
        CommandClass::SENSOR_BINARY => CommandClasses::SensorBinary,
        CommandClass::WAKEUP => CommandClasses::WakeUp,
        CommandClass::ALARM => CommandClasses::Alarm,
        CommandClass::ALARM_SENSOR => CommandClasses::AlarmSensor,
        CommandClass::BATTERY => CommandClasses::Battery
      }
    end
  end
end
