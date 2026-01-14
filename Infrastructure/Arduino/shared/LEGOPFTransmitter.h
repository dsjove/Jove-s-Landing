#pragma once
#include "BLEServiceRunner.h"

struct PFCommand;

class LEGOPFTransmitter {
public:
  LEGOPFTransmitter(BLEServiceRunner& ble, int pin);
  void begin();

private:
  int _pin;
  uint8_t _gA[4];
  uint8_t _gB[4];

  BLECharacteristic _transmitChar;
  static void transmit(BLEDevice device, BLECharacteristic characteristic);
  void transmit(const PFCommand& command);
};
