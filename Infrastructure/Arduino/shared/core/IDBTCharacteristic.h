// IDBTCharacteristic.h
#pragma once

#include <ArduinoBLE.h>

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>

//BLECharacteristic does NOT copy the uuid!
//It must stay in memory.
struct IDBTCharacteristic {
  const std::array<char, 37> uuid;
  BLECharacteristic characteristic;

  IDBTCharacteristic(
    const std::string& propertyId, // hex of 4 byte id
    const std::string& serviceId, // hex of 12 byte id
    int valueSize, // store value of this size
    const void* value, // initial value of valueSize
    BLECharacteristicEventHandler eventHandler);
};
