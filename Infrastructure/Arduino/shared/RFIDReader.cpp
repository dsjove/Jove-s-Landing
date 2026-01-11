#include "RFIDReader.h"

static RFIDReader* rfidReaderRef = NULL;

RFIDReader::RFIDReader(BLEServiceRunner& ble, int ss_pin, int rst_pin)
: _ble(ble)
, _ss_pin(ss_pin)
, _rst_pin(rst_pin)
, _wasPresent(-1)
, _lastID({0})
, _cooldownUntilMs(0)
, _idFeedbackChar(ble.characteristic("05040002", &_lastID))
, _rfidTask(20, TASK_FOREVER, &readId_task)
{
  rfidReaderRef = this;
}

void RFIDReader::begin(Scheduler& scheduler)
{
  Serial.println(_idFeedbackChar.uuid());
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

  Value newID = { 0 };

  if (_rfid.PICC_IsNewCardPresent())
  {
    // Reader tells new card is present
    if (_wasPresent != 1) 
    {
      _wasPresent = 1;
      Serial.print("+");
    }
    // Don't span the reader and bluetooth
    if (now < _cooldownUntilMs)
    {
      Serial.print("O");
      return;
    }
    // Read the serial number
    if (_rfid.PICC_ReadCardSerial()) 
    {
      newID = toMemento(_rfid.uid);

      // Always end the (read) conversation with the tag
      _rfid.PICC_HaltA();
      _rfid.PCD_StopCrypto1();

      // If it is a different tag then broadcast
      if (!sameValue(newID, _lastID))
      {
        printUid(newID);
        _lastID = newID;
        // ID staleness is a client concern
        _idFeedbackChar.writeValue(_lastID.data(), _lastID[0] + 1);
      }
      else
      {
        Serial.println("=");
      }
      // Start cooldown after a successful publish
      // Same card as last publish: still start cooldown to avoid rapid repeats
      static constexpr uint32_t kCooldownMs = 800; // tune for your train speed
      _cooldownUntilMs = now + kCooldownMs;
    }
    else 
    {
        //Failed to read card serial
        Serial.println("!");
    }
  }
  else 
  {
    // Reader has provided events
    if (_wasPresent != 0) 
    {
      _wasPresent = 0;
      Serial.println("X");
    }
  }
}

RFIDReader::Value RFIDReader::toMemento(const MFRC522::Uid& u)
{
  Value value;
  value[0] = u.size;
  std::copy(u.uidByte, u.uidByte + u.size, value.begin() + 1);
  return value;
}

bool RFIDReader::sameValue(const Value& a, const Value& b)
{
  if (a[0] != b[0]) return false;
  const uint8_t len = a[0];
  for (uint8_t i = 0; i < len; i++)
  {
    if (a[i + 1] != b[i + 1]) return false;
  }
  return true;
}

void RFIDReader::printUid(const Value& u) {
  Serial.print("RFID UID (");
  Serial.print(u[0]);
  Serial.print("): ");
  for (size_t i = 1; i <= u[0]; i++) {
    if (u[i] < 0x10) Serial.print('0');
    Serial.print(u[i], HEX);
    Serial.print(' ');
  }
  Serial.println();
}
