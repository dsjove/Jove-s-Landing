#pragma once
#include "BLEServiceRunner.h"
#include <MFRC522.h>

class RFIDReader {
public:
  using Value = std::array<uint8_t, 11>;

  RFIDReader(BLEServiceRunner& ble, int ss_pin, int rst_pin);
  void begin(Scheduler& scheduler);

private:
  BLEServiceRunner& _ble;
  const int _ss_pin;
  const int _rst_pin;

  MFRC522 _rfid;

  int _wasPresent;
  Value _lastID;
  uint32_t _timeStamp;

  BLECharacteristic _idFeedbackChar;

  Task _rfidTask;
  static void readId_task();
  void readId();

  static Value toMemento(const MFRC522::Uid& u);
  static bool sameValue(const Value& a, const Value& b);
  static void printUid(const Value& u);
};
