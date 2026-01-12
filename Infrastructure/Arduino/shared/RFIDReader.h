#pragma once
#include "BLEServiceRunner.h"
#include <MFRC522.h>

class RFIDReader {
public:
  RFIDReader(BLEServiceRunner& ble, uint32_t number, int ss_pin = 10, int rst_pin = 9);
  void begin(Scheduler& scheduler);

private:
  struct RFID {
    using Value = std::array<uint8_t, 4 + 4 + 1 + 10>;

    RFID(uint32_t number);
    void encode(const MFRC522::Uid& u, uint32_t timestamp);
    size_t size() const;
    const uint8_t* data() const;
    void print() const;

  private:
    Value _value;
  };

  BLEServiceRunner& _ble;
  const int _ss_pin;
  const int _rst_pin;

  MFRC522 _rfid;

  int _wasPresent;
  RFID _lastID;
  uint32_t _timeStamp;

  BLECharacteristic _idFeedbackChar;
  Task _rfidTask;

  uint32_t _lastGoodReadMs;
  uint32_t _failReadCount;

  static void readId_task();
  void readId();
  void resetRc522();
};
