#pragma once

#include "core/TaskThunk.h"
#include "core/IDBTCharacteristic.h"
#include "core/MFRC522Detector.h"

class RFIDBroadcaster : ScheduledRunner
{
public:
  RFIDBroadcaster(Scheduler& scheduler, BLEServiceRunner& ble, uint32_t number, int ss_pin = 10, int rst_pin = 9);

  void begin();

private:
  MFRC522Detector _rfid;
  IDBTCharacteristic _idFeedbackChar;
  TaskThunk _rfidTask;

  virtual void loop(Task&);
};
