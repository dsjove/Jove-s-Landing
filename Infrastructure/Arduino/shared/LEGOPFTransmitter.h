#pragma once
#include "core/BLEServiceRunner.h"
#include "core/LegoPFIR.h"

class LEGOPFTransmitter {
public:
  LEGOPFTransmitter(BLEServiceRunner& ble, int pin = 8);
  void begin();

private:
  LegoPFIR _ir;
  IDBTCharacteristic _transmitChar;
  static void transmit(BLEDevice device, BLECharacteristic characteristic);
};
