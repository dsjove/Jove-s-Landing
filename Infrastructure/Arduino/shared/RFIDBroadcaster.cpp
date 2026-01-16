#include "RFIDBroadcaster.h"

static RFIDBroadcaster* RFIDBroadcasterRef = NULL;

RFIDBroadcaster::RFIDBroadcaster(BLEServiceRunner& ble, uint32_t number, int ss_pin, int rst_pin)
: _rfid(number, ss_pin, rst_pin)
, _rfidTask(_rfid.timing().taskFrequency, TASK_FOREVER, &readId_task)
, _idFeedbackChar(ble, "05000002", _rfid.lastID().encode())
{
  RFIDBroadcasterRef = this;
}

void RFIDBroadcaster::begin(Scheduler& scheduler)
{
  _rfid.begin();
  Serial.print("RFID: ");
  _rfid.lastID().print();
  Serial.println();
  scheduler.addTask(_rfidTask);
  _rfidTask.enable();
}

void RFIDBroadcaster::readId_task()
{
  const MFRC522Detector::RFID* detected = RFIDBroadcasterRef->_rfid.loop();
  if (detected)
  {
      auto encoded = detected->encode();
      Serial.print("RFID: ");
      detected->print();
//      Serial.print(" -- ");
//      MFRC522Detector::RFID::print(encoded);
      Serial.println();
//      Serial.println(RFIDBroadcasterRef->_idFeedbackChar.uuid.data());
      RFIDBroadcasterRef->_idFeedbackChar.ble.writeValue(encoded.data(), detected->encodedSize());
  }
}
