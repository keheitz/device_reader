# frozen_string_literal: true

require 'test_helper'

class DeviceTest < ActiveSupport::TestCase
  test 'device should be invalid without id' do
    device = Device.new(nil)
    assert device.invalid?, 'Device valid without id'
  end

  test 'device cumulative count sums cached reading counts' do
    readings = [{ timestamp: '2022-11-17T03:21:14Z', count: 1 }, { timestamp: '2022-11-17T03:21:25Z', count: 4 },
                { timestamp: '2022-11-17T03:21:34Z', count: 5 }]
    device = Device.new('2fc45040-8ccb-4ed8-9a8e-42bc3472883a')
    Rails.cache.write('2fc45040-8ccb-4ed8-9a8e-42bc3472883a', readings)
    assert_equal 10, device.cumulative_count, "Cumulative count doesn't match cache count sum"
  end

  test 'duplicate payloads should be ignored' do
    readings = [{ timestamp: '2022-11-17T03:21:14Z', count: 1 }, { timestamp: '2022-11-17T03:21:25Z', count: 4 },
                { timestamp: '2022-11-17T03:21:34Z', count: 5 }]
    readings_2 = [{ timestamp: '2022-10-17T03:21:14Z', count: 2 },
                  { timestamp: '2022-09-17T03:21:25Z', count: 3 }]
    device = Device.new('2fc45040-8ccb-4ed8-9a8e-42bc3472883a')
    device.update_readings_cache(readings)
    device.update_readings_cache(readings_2)
    device.update_readings_cache(readings)
    assert_equal 15, device.cumulative_count, 'Cumulative count includes duplicate payload readings'
  end
end
