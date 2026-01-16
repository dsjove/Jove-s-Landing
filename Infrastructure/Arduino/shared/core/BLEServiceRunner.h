#pragma once

#include "btutil.h"
#include <string>
#include <ArduinoBLE.h>
#include <TaskScheduler.h>

class BLEServiceRunner
{
public:
  BLEServiceRunner(const std::string& serviceName, const std::string& overrideId = "");

  void addCharacteristic(BLECharacteristic& ble);

  const BLEUUID& serviceId() const { return _serviceId; }

  void begin(Scheduler& scheduler);

private:
  const std::string _name;
  const BLEUUID _serviceId;
  BLEService _bleService;
  Task _bluetoothTask;

  static void bluetooth_task();
  static void bluetooth_connected(BLEDevice device);
  static void bluetooth_disconnected(BLEDevice device);
};
