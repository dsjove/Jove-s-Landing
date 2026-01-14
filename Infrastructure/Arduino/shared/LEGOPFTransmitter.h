#pragma once
#include "BLEServiceRunner.h"
#include "LegoPFIR.h"

class LEGOPFTransmitter {
public:
  LEGOPFTransmitter(BLEServiceRunner& ble, int pin);
  void begin();

private:
  LegoPFIR _ir;

  BLECharacteristic _transmitChar;
  static void transmit(BLEDevice device, BLECharacteristic characteristic);
};
