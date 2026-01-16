#pragma once

#include "btutil.h"

class BLEServiceRunner;

struct IDBTCharacteristic {
  const BLEUUID uuid;
  BLECharacteristic ble;

  IDBTCharacteristic(
    BLEServiceRunner& runner,
    const std::string& propertyId, // hex of 4 byte id
    size_t valueSize, // store value of this size
    const void* value, // initial value of valueSize
    BLECharacteristicEventHandler eventHandler);

  template <typename T>
  IDBTCharacteristic(
    BLEServiceRunner& runner,
    const std::string& propertyId,
    const T* value,
    BLECharacteristicEventHandler eventHandler = NULL)
    : IDBTCharacteristic(runner, propertyId, sizeof(T), value, eventHandler) {}

  template <typename T, std::size_t N>
  IDBTCharacteristic(
    BLEServiceRunner& runner,
    const std::string& propertyId,
    const std::array<T, N>& value,
    BLECharacteristicEventHandler eventHandler = NULL)
    : IDBTCharacteristic(runner, propertyId, value.size(), value.data(), eventHandler) {}
};
