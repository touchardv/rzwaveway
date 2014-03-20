require 'spec_helper'

include RZWaveWay::CommandClasses

describe RZWaveWay::CommandClass do
  before :each do
    @command_class = RZWaveWay::CommandClass.new(
      WAKEUP, {'data' => {
        'interval' => {'value' => 300},
        'lastSleep' => {'value' => 1394983221},
        'lastWakeup' => {'value' => 1394983222}
        }
      })
  end

  it 'stores interesting properties' do
    @command_class.id.should eql WAKEUP
    @command_class.properties['lastSleepTime'].should eql 1394983221
    @command_class.properties['lastWakeUpTime'].should eql 1394983222    
  end

  it 'does nothing when it processes no updates' do
    @command_class.process({}, 2).should eql nil
  end

  it 'processes updates and generates an AliveEvent' do
    updates = {
      'data.lastWakeup' => {'value' => 1395247772},
      'data.lastSleep' => {'value' => 1395247772}      
    }
    event = @command_class.process(updates, 2)
    event.is_a? RZWaveWay::AliveEvent
    event.device_id.should eql 2
    event.time.should eql 1395247772
    @command_class.properties['lastSleepTime'].should eql 1395247772
    @command_class.properties['lastWakeUpTime'].should eql 1395247772    
  end

  it 'processes updates and generates an AliveEvent only once' do
    updates = {
      'data.lastWakeup' => {'value' => 1395247772},
      'data.lastSleep' => {'value' => 1395247772}      
    }
    event = @command_class.process(updates, 2)
    event = @command_class.process(updates, 2)
    event.should eql nil
  end

  it 'generates a NotAliveEvent' do
    # TODO
  end

  it 'does not generate a NotAliveEvent at each check' do
    # TODO
  end

  it 'generates a DeadEvent' do
    # TODO
  end

  it 'does not generate a DeadEvent multiple times' do
    # TODO
  end
end