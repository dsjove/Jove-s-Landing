#include "BLEServiceRunner.h"

std::string generateID(const std::string& name, const std::string& serviceID)
{
  std::string result;
  result.reserve(37);
  result.append(8, '0');
  result.push_back('-');

  if (!serviceID.empty()) 
  {
    result.append(serviceID);
  }
  else
  {
    size_t i = 0;
    for (; i < 12 && i < name.length(); i++)
    {
      char output[3];
      sprintf(output, "%02X", name[i]);
      result.append(output);
      if (i == 1 || i == 3 || i == 5)
      {
        result.push_back('-');
      }
    }
    if (i < 12)
    {
      result.append((12 - i) * 2, '0');
    }
  }
  return result;
}

BLEServiceRunner::BLEServiceRunner(const std::string& name, const std::string& serviceID)
: _name(name)
, _id(generateID(name, serviceID))
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

BLECharacteristic BLEServiceRunner::characteristic(const std::string& id, size_t size, const void* value, BLECharacteristicEventHandler eventHandler)
{
  std::string fullID(id.substr(0, 8));
  fullID.append(_id.substr(9));

  uint16_t permissions = 0;
  if (value)
  {
    permissions |= BLERead;
    permissions |= BLENotify;
  }
  if (eventHandler)
  {
    permissions |= BLEWriteWithoutResponse;
  }
  BLECharacteristic characteristic(fullID.c_str(), permissions, size);
  if (value) 
  {
    characteristic.writeValue(value, size);
  }
  if (eventHandler)
  {
    characteristic.setEventHandler(BLEWritten, eventHandler);
  }
  _bleService.addCharacteristic(characteristic);
  return characteristic;
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
