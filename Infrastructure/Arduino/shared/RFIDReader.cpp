#include "RFIDReader.h"

#include <stdint.h>

// Max bytes for a 64-bit ULEB128 / protobuf varint
static constexpr size_t kMaxVarint64Bytes = 10;

// Encodes value into buffer.
// Returns number of bytes written (1..10).
size_t encodeULEB128_u64(uint64_t value, uint8_t* buffer) {
  size_t i = 0;
  do {
    uint8_t byte = static_cast<uint8_t>(value & 0x7FULL); // lower 7 bits
    value >>= 7;
    if (value != 0) byte |= 0x80;                         // continuation
    buffer[i++] = byte;
  } while (value != 0 && i < kMaxVarint64Bytes);

  // For uint64_t, i will never exceed 10 with correct logic above.
  return i;
}

// Decodes from buffer into 'value'.
// Returns true on success and sets:
//   - value
//   - bytesConsumed (1..10)
// Returns false if input is malformed or would overflow uint64_t.
//
// NOTE: You must ensure 'buffer' has at least 10 readable bytes OR stop earlier
// based on your framing (length-delimited packet, etc.).
bool decodeULEB128_u64(const uint8_t* buffer, size_t bufferLen,
                       uint64_t& value, size_t& bytesConsumed) {
  value = 0;
  bytesConsumed = 0;

  uint32_t shift = 0;

  for (size_t i = 0; i < kMaxVarint64Bytes; ++i) {
    if (i >= bufferLen) return false; // not enough data

    uint8_t byte = buffer[i];
    uint64_t slice = static_cast<uint64_t>(byte & 0x7F);

    // Overflow check:
    // - For shifts 0..63, we can place bits.
    // - If shift == 63, only 1 bit could fit; but varints place 7 bits at a time.
    // Practical protobuf rule: on the 10th byte (i==9), only the low 1 bit may be set
    // (because 64 bits total).
    if (shift >= 64) return false;

    if (i == 9) {
      // 10th byte: only bit0 is allowed (values 0 or 1), and continuation must be 0
      if ((byte & 0xFE) != 0) return false;  // any bits beyond bit0 set => overflow
      if ((byte & 0x80) != 0) return false;  // continuation on 10th byte is invalid
    }

    value |= (slice << shift);
    bytesConsumed = i + 1;

    if ((byte & 0x80) == 0) {
      return true; // finished
    }

    shift += 7;
  }

  // If we consumed 10 bytes and still had continuation, it's malformed.
  return false;
}

/*
uint8_t buf[10];
uint64_t original = 300ULL;

size_t n = encodeULEB128_u64(original, buf);

uint64_t decoded = 0;
size_t consumed = 0;
bool ok = decodeULEB128_u64(buf, n, decoded, consumed);
 */

static RFIDReader* rfidReaderRef = NULL;

RFIDReader::RFIDReader(BLEServiceRunner& ble, int ss_pin, int rst_pin)
: _ble(ble)
, _ss_pin(ss_pin)
, _rst_pin(rst_pin)
, _rfid(ss_pin, rst_pin)
, _wasPresent(-1)
, _lastID({0})
, _timeStamp(0)
, _idFeedbackChar(ble.characteristic("05040002", &_lastID))
, _rfidTask(20, TASK_FOREVER, &readId_task)
, _lastGoodReadMs(0)
, _failReadCount(0)   
{
  rfidReaderRef = this;
}

void RFIDReader::begin(Scheduler& scheduler)
{
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
  static constexpr uint32_t kCooldownMs = 800; // tune for tag movement speed
  static constexpr uint32_t kReinitAfterMs = 30000; // MFRC522 goes bad after a while
  static constexpr uint8_t kFailResetCount = 5; // Reset after a failure count

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
    if (_wasPresent != 1) 
    {
      _wasPresent = 1;
       //Serial.println("RFID: New Card");
    }
    // Cooldown gate (prevents spamming reads/ble)
    if (now < _timeStamp)
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

      Value newID = toMemento(_rfid.uid);

      // Always end the (read) conversation with the tag
      _rfid.PICC_HaltA();
      _rfid.PCD_StopCrypto1();

      // Start cooldown after successful read
      _timeStamp = now + kCooldownMs;

      printUid(newID);
      _lastID = newID;

      std::array<uint8_t, 4 + 11> blePayload;
      const uint8_t valueBytes = 1 + _lastID[0];
      const uint8_t totalLen = 4 + valueBytes;

      const uint32_t ts = now;
      std::copy(
        reinterpret_cast<const uint8_t*>(&ts),
        reinterpret_cast<const uint8_t*>(&ts) + sizeof(ts),
        blePayload.begin()
      );

      std::copy(
        _lastID.begin(),
        _lastID.begin() + valueBytes,
        blePayload.begin() + sizeof(ts)
      );

      _idFeedbackChar.writeValue(blePayload.data(), totalLen);
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
  }
  else 
  {
    // Reader has provided events
    if (_wasPresent != 0) 
    {
      _wasPresent = 0;
      // Serial.println("RFID: Removed Card");
    }
  }
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

RFIDReader::Value RFIDReader::toMemento(const MFRC522::Uid& u)
{
  Value value;
  //value.fill(0); Not necessary
  const uint8_t len = (u.size > 10) ? 10 : u.size;
  value[0] = len;
  std::copy(u.uidByte, u.uidByte + len, value.begin() + 1);
  return value;
}

bool RFIDReader::sameValue(const Value& a, const Value& b)
{
  if (a[0] != b[0]) return false;
  const uint8_t len = (a[0] > 10) ? 10 : a[0];
  for (uint8_t i = 0; i < len; i++)
  {
    if (a[i + 1] != b[i + 1]) return false;
  }
  return true;
}

void RFIDReader::printUid(const Value& u) {
  Serial.print("RFID: UID (");
  Serial.print(u[0]);
  Serial.print("): ");
  for (size_t i = 1; i <= u[0]; i++) {
    if (u[i] < 0x10) Serial.print('0');
    Serial.print(u[i], HEX);
    Serial.print(' ');
  }
  Serial.println();
}
