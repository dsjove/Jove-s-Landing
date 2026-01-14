#include "LEGOPFTransmitter.h"

static LEGOPFTransmitter* pfTranbsmitterRef = NULL;

LEGOPFTransmitter::LEGOPFTransmitter(BLEServiceRunner& ble, int pin)
: _ir(pin)
, _transmitChar(ble.characteristic("05020000", 3, NULL, transmit))
{
  pfTranbsmitterRef = this;
}

void LEGOPFTransmitter::begin()
{
  _ir.begin();
}

void LEGOPFTransmitter::transmit(BLEDevice, BLECharacteristic characteristic)
{
  std::array<uint8_t, 3> value;
  characteristic.readValue(value.data(), sizeof(value));
  LegoPFIR::Command command = { value[0], (LegoPFIR::Port)value[1], value[2] };
  pfTranbsmitterRef->_ir.apply(command);
	Serial.println(command.channel);
	Serial.println((int)command.port);
	Serial.println(command.value);
}
