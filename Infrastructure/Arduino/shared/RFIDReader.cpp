#include "RFIDReader.h"

static RFIDReader* rfidReaderRef = NULL;

// Timing constants
static constexpr uint32_t kTaskFrequency = 20;
static constexpr uint32_t kCooldownMs = 800; // Tune for tag movement speed
static constexpr uint32_t kReinitAfterMs = 30000; // MFRC522 goes bad after a while
static constexpr uint8_t kFailResetCount = 5; // Reset after a failure count

RFIDReader::RFIDReader(BLEServiceRunner& ble, uint32_t number, int ss_pin, int rst_pin)
: _ss_pin(ss_pin)
, _rst_pin(rst_pin)
, _rfid(ss_pin, rst_pin)
, _rfidTask(kTaskFrequency, TASK_FOREVER, &readId_task)
, _lastID(number)
, _cooldownLimitMs(0)
, _lastGoodReadMs(0)
, _failReadCount(0)  
, _idFeedbackChar(ble.characteristic("05040002", _lastID.size(), _lastID.data(), NULL)) 
{
  rfidReaderRef = this;
}

void RFIDReader::begin(Scheduler& scheduler)
{
  _lastID.print();
  pinMode(_rst_pin, OUTPUT);
  digitalWrite(_rst_pin, HIGH);
  _rfid.PCD_Init();
  scheduler.addTask(_rfidTask);
  _rfidTask.enable();
}

void RFIDReader::readId_task()
{
  rfidReaderRef->readId();
}

void RFIDReader::readId()
{
  const uint32_t now = millis();

  // Re-init after long inactivity without a successful read
  if (_lastGoodReadMs != 0 && (now - _lastGoodReadMs) > kReinitAfterMs)
  {
    //Serial.println("RFID: Inactivity Reset");
    resetRc522();
    _lastGoodReadMs = now;
  }

  if (_rfid.PICC_IsNewCardPresent())
  {
    // Reader tells new card is present
	//Serial.println("RFID: New Card");

    // Cooldown gate (prevents spamming rf reads and ble writes)
    if (now < _cooldownLimitMs)
    {
      //Serial.println("RFID: Cooldown");
      return;
    }
    // Read the serial number
    if (_rfid.PICC_ReadCardSerial()) 
    {
      // Record a good read time
      _lastGoodReadMs = now;
      _failReadCount = 0;

      _lastID.encode(_rfid.uid, now);

      // Always end the (read) conversation with the tag
      _rfid.PICC_HaltA();
      _rfid.PCD_StopCrypto1();

      // Start cooldown after successful read
      _cooldownLimitMs = now + kCooldownMs;

      // Report change ID or timestamp
      _lastID.print();
      _idFeedbackChar.writeValue(_lastID.data(), _lastID.size());
    }
    else 
    {
      Serial.println("RFID: Read Failed");
      // Cleanup even on failed read (prevents wedged state)
      _rfid.PCD_StopCrypto1();
      _rfid.PICC_HaltA();

      _failReadCount++;

      // Hard reset after repeated failures
      if (_failReadCount >= kFailResetCount)
      {
        Serial.println("RFID: Fail Count Reset");
        resetRc522();
      }
    }
  } // else Hovering not detectable.
}

void RFIDReader::resetRc522()
{
  // Hard reset the RC522 using its RST pin
  digitalWrite(_rst_pin, LOW);
  delay(5);
  digitalWrite(_rst_pin, HIGH);
  delay(5);

  _rfid.PCD_Init();
  // Optional: max gain can improve marginal reads
  _rfid.PCD_SetAntennaGain(_rfid.RxGain_max);
  _failReadCount = 0;
  //Do not reset _lastGoodReadMs
}

RFIDReader::RFID::RFID(uint32_t _number)
{
  _value.fill(0);
  const uint32_t number = _number;
  std::copy(
    reinterpret_cast<const uint8_t*>(&number),
    reinterpret_cast<const uint8_t*>(&number) + sizeof(number),
    _value.begin()
  );
  _value[8] = 10;
}

size_t RFIDReader::RFID::size() const
{
  return 4 + 4 + 1 + _value[8];
}

const uint8_t* RFIDReader::RFID::data() const
{
  return _value.data();
}

void RFIDReader::RFID::encode(const MFRC522::Uid& u, uint32_t timestamp)
{
  const uint32_t ts = timestamp;
  std::copy(
    reinterpret_cast<const uint8_t*>(&ts),
    reinterpret_cast<const uint8_t*>(&ts) + sizeof(ts),
    _value.begin() + 4
  );
  const uint8_t len = (u.size > 10) ? 10 : u.size;
  _value[8] = len;
  std::copy(u.uidByte, u.uidByte + len, _value.begin() + 9);
}

void RFIDReader::RFID::print() const {
  Serial.print("RFID: UID (");
  Serial.print(size());
  Serial.print("): ");
  for (size_t i = 0; i < size(); i++) {
    if (_value[i] < 0x10) Serial.print('0');
    Serial.print(_value[i], HEX);
    if (i == 3 || i == 7 || i == 8) Serial.print('-');
  }
  Serial.println();
}
