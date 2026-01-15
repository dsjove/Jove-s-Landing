#pragma once
#include "core/BLEServiceRunner.h"
#include <Arduino_LED_Matrix.h>

class MatrixR4
{
public:
  using Value = std::array<uint32_t, 3>;

  MatrixR4(BLEServiceRunner& ble, const Value& value = {0, 0, 0});

  void begin();

private:
  Value _current;

  BLECharacteristic _displayChar;
  static void updateDisplay(BLEDevice device, BLECharacteristic characteristic);

  ArduinoLEDMatrix _matrix;

  void set(const Value& data);
};
