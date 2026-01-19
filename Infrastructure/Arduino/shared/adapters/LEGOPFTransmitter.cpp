#include "LEGOPFTransmitter.h"

static LEGOPFTransmitter* pfTranbsmitterRef = NULL;

LEGOPFTransmitter::LEGOPFTransmitter(Scheduler& scheduler, BLEServiceRunner& ble, int pin)
: _ir(pin)
, _transmitChar(ble, "05020000", 4, NULL, transmit)
, _task(scheduler, 1000, this, false)
{
  pfTranbsmitterRef = this;
}

void LEGOPFTransmitter::begin()
{
  _ir.begin();
}

void LEGOPFTransmitter::loop(Task&) {
  _ir.refreshAll();
}

void LEGOPFTransmitter::transmit(BLEDevice, BLECharacteristic characteristic)
{
  //TODO: have a 3rd mode of combo w/ task enabled, lineOfSight
  std::array<uint8_t, 4> value;
  characteristic.readValue(value.data(), value.size());
  LegoPFIR::Command command = {
    value[0],
    (LegoPFIR::Port)value[1],
    value[2],
    (LegoPFIR::Mode)value[3]
  };
  pfTranbsmitterRef->_ir.apply(command);
}
