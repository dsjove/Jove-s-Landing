#pragma once
#include <MFRC522.h>

class MFRC522Detector {
public:
  static constexpr uint32_t kTaskFrequency = 20;

  struct RFID {
    using Encoded = std::array<uint8_t, 4 + 4 + 1 + 10>;

    RFID(uint32_t number);
    void update(const MFRC522::Uid& u, uint32_t timestamp);
    void print() const;

    const uint32_t _number;
    uint32_t _timestamp;
    uint8_t _length;
    std::array<uint8_t, 10> _uuid;

    Encoded encode() const;
    size_t encodedSize() const { return 4 + 4 + 1 + _length; }

    static void print(const Encoded& encoded);
  };

  MFRC522Detector(uint32_t number, int ss_pin = 10, int rst_pin = 9);

  void begin();

  const RFID* loop();

  const RFID& lastID() const { return _lastID; }

private:
  const int _ss_pin;
  const int _rst_pin;
  MFRC522 _rfid;
  RFID _lastID;
  uint32_t _cooldownLimitMs;
  uint32_t _lastGoodReadMs;
  uint32_t _failReadCount;

  void resetRc522();
};
