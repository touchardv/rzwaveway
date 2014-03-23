require 'spec_helper'

include RZWaveWay::CommandClasses

describe RZWaveWay::CommandClass do

  before :each do
    @command_class = RZWaveWay::CommandClass.new(
      WAKEUP, {'data' => {
                 'interval' => {'value' => 300},
                 'lastSleep' => {'value' => 1394983221},
                 'lastWakeup' => {'value' => 1394983222}
    }})
  end

  describe '#new' do
    it 'stores interesting properties' do
      @command_class.id.should eql WAKEUP
      @command_class.properties['lastSleepTime'].should eql 1394983221
      @command_class.properties['lastWakeUpTime'].should eql 1394983222
    end
  end

  describe '#process' do
    it 'does nothing when it processes no updates' do
      @command_class.process({}, 2).should eql nil
    end

    it 'processes updates and generates an AliveEvent' do
      updates = {
        'data.lastWakeup' => {'value' => 1395247772},
        'data.lastSleep' => {'value' => 1395247772}
      }
      event = @command_class.process(updates, 2)
      event.class.should eql RZWaveWay::AliveEvent
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
  end

  describe '#process_alive_check' do
    context 'when missed one wakeup' do
      before(:each) { @command_class.properties['lastSleepTime'] = Time.now.to_i - 600 }

      it 'generates a NotAliveEvent' do
        event = @command_class.process_alive_check(2)
        event.class.should eql  RZWaveWay::NotAliveEvent
        event.device_id.should eql 2
      end

      it 'does not generate a NotAliveEvent at each check' do
        event = @command_class.process_alive_check(2)
        event = @command_class.process_alive_check(2)
        event.should eql nil
      end
    end

    context 'when missed more than 10 wakeups' do
      before(:each) {@command_class.properties['lastSleepTime'] = Time.now.to_i - 6000}

      it 'generates a DeadEvent' do
        event = @command_class.process_alive_check(2)
        event.class.should eql  RZWaveWay::DeadEvent
        event.device_id.should eql 2
      end

      it 'does not generate a DeadEvent multiple times' do
        event = @command_class.process_alive_check(2)
        event = @command_class.process_alive_check(2)
        event.should eql nil
      end
    end
  end
end
