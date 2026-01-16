#include "BLEServiceRunner.h"

BLEServiceRunner::BLEServiceRunner(const std::string& serviceName, const std::string& overrideId)
: _name(serviceName)
, _serviceId(btutil::makeUuidWithService(serviceName, overrideId))
, _bleService(_serviceId.data())
, _bluetoothTask(100, TASK_FOREVER, &bluetooth_task)
{
}

void BLEServiceRunner::addCharacteristic(BLECharacteristic& ble)
{
  _bleService.addCharacteristic(ble);
}

void BLEServiceRunner::begin(Scheduler& scheduler)
{
  if (!BLE.begin()) 
  {
    Serial.println("Starting Bluetooth® Low Energy module failed!");
    while (1);
  }
  BLE.setLocalName(_name.c_str());
  BLE.setEventHandler(BLEConnected, bluetooth_connected);
  BLE.setEventHandler(BLEDisconnected, bluetooth_disconnected);
  
  BLE.setAdvertisedService(_bleService);
  BLE.addService(_bleService);

  int r = BLE.advertise();
  if (r == 1) 
  {
    Serial.println("Bluetooth® device active.");
    Serial.print(_name.c_str());
    Serial.print(": ");
    Serial.println(_serviceId.data());
  }
  else 
  {
    Serial.println("Bluetooth® activation failed!");
    while (1);
  }
  scheduler.addTask(_bluetoothTask);
  _bluetoothTask.enable();
}

void BLEServiceRunner::bluetooth_task() 
{
  BLE.poll();
}

void BLEServiceRunner::bluetooth_connected(BLEDevice device) 
{
  Serial.println();
  Serial.print("BT Connected: ");
  Serial.println(device.address());
}

void BLEServiceRunner::bluetooth_disconnected(BLEDevice device) 
{
  Serial.println();
  Serial.print("BT Disconnected: ");
  Serial.println(device.address());
}
