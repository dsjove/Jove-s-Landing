#pragma once

#include "core/IDBTCharacteristic.h"
#include "core/MFRC522Detector.h"

class RFIDBroadcaster {
public:
  RFIDBroadcaster(BLEServiceRunner& ble, uint32_t number, int ss_pin = 10, int rst_pin = 9);

  void begin(Scheduler& scheduler);

private:
  MFRC522Detector _rfid;
  Task _rfidTask;
  IDBTCharacteristic _idFeedbackChar;

  static void readId_task();
};
