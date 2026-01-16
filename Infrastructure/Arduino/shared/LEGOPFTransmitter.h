#pragma once

#include "core/IDBTCharacteristic.h"
#include "core/LegoPFIR.h"

class LEGOPFTransmitter {
public:
  LEGOPFTransmitter(BLEServiceRunner& ble, int pin);

  void begin();

private:
  LegoPFIR _ir;
  IDBTCharacteristic _transmitChar;
  static void transmit(BLEDevice device, BLECharacteristic characteristic);
};
