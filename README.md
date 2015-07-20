rzwaveway
=========

A Ruby library for communicating with the ZWave protocol stack from ZWay, running on the Raspberry Pi "razberry" add-on card (see http://razberry.z-wave.me/).

## Usage examples

### Initialize the framework
```
require 'rzwaveway'

z_way = RZWaveWay::ZWay.instance
z_way.setup('192.168.1.123')
z_way.start
```

### List the devices
```
z_way.devices.each do |device_id,device|
  puts device.build_json
end
```

### Listen to events
```
z_way.on_event(RZWaveWay::AliveEvent) {|event| puts "A device woke up" }
z_way.on_event(RZWaveWay::LevelEvent) {|event| puts "A device got triggered" }
while true do
  sleep 5
  z_way.process_events
end
```

### Switch on/off a device
```
z_way.execute(4, RZWaveWay::CommandClass::SWITCH_BINARY, :Set, 1)
z_way.execute(4, RZWaveWay::CommandClass::SWITCH_BINARY, :Set, 0)
````
