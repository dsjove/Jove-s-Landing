#include "LEGOPFTransmitter.h"

static LEGOPFTransmitter* pfTranbsmitterRef = NULL;

char d[3] = {0, 0, 0};

LEGOPFTransmitter::LEGOPFTransmitter(BLEServiceRunner& ble, int pin)
: _ir(pin)
, _transmitChar(ble, "05020000", 3, d, transmit)
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
  characteristic.readValue(value.data(), value.size());
  LegoPFIR::Command command = { value[0], (LegoPFIR::Port)value[1], value[2] };
    Serial.println(characteristic.uuid());
	Serial.println(command.channel);
	Serial.println((int)command.port);
	Serial.println(command.value);
  pfTranbsmitterRef->_ir.apply(command);
}
