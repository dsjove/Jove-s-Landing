#include "shared/BLEServiceRunner.cpp"
#include "shared/MatrixR4.cpp"
#include "shared/Lighting.cpp"
#include "shared/RFIDBroadcaster.cpp"
#include "shared/LEGOPFTransmitter.cpp"
#include "shared/core/LegoPFIR.cpp"
#include "shared/core/MFRC522Detector.cpp"

#include <SPI.h>

#include <TaskScheduler.h>

Scheduler _runner;
BLEServiceRunner _ble("City Streets");
MatrixR4 _matrixR4(_ble); // {0xB194a444, 0x44042081, 0x100a0841}
Lighting _lighting(_ble, {{3, true}, {0, false}}, A0);
RFIDBroadcaster _RFIDBroadcaster(_ble, 1);
LEGOPFTransmitter _pfTransmitter(_ble, 16);

void setup()
{
  Serial.begin(9600);
  while (!Serial);

  SPI.begin();

  _ble.begin(_runner);
  _matrixR4.begin();
  _lighting.begin(_runner);
  _RFIDBroadcaster.begin(_runner);
  _pfTransmitter.begin();
}

void loop()
{
  _runner.execute();
}

//#include <EEPROM.h>
//const int _epromIdxFirstRun = 0;
//bool _firstRun = true;
  //_firstRun = EEPROM.read(_epromIdxFirstRun) == 0;
  //if (_firstRun) {
    //Serial.println("First Run!");
    //EEPROM.write(_epromIdxFirstRun, 1);
  //}
