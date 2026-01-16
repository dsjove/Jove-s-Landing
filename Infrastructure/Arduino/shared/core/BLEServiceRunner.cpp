#include "BLEServiceRunner.h"
#include "IDBTCharacteristic.cpp"

BLEServiceRunner::BLEServiceRunner(const std::string& name, const std::string& serviceID)
: _name(name)
, _id(btutil::generateServiceID(name, serviceID))
, _bleService(_id.c_str())
, _bluetoothTask(100, TASK_FOREVER, &bluetooth_task)
{
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
    Serial.println(_id.c_str());
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

IDBTCharacteristic BLEServiceRunner::characteristic(const std::string& id, size_t size, const void* value, BLECharacteristicEventHandler eventHandler)
{
  IDBTCharacteristic idchar(_id, id, size,value, eventHandler);
  _bleService.addCharacteristic(idchar.characteristic);
  return idchar;
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
