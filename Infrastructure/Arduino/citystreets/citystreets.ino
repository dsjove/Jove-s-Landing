#include "shared/BLEServiceRunner.cpp"
#include "shared/MatrixR4.cpp"
#include "shared/Lighting.cpp"
#include "shared/RFIDReader.cpp"

#include <SPI.h>

#include <TaskScheduler.h>

Scheduler _runner;
BLEServiceRunner _ble("City Streets");
MatrixR4 _matrixR4(_ble); // {0xB194a444, 0x44042081, 0x100a0841}
Lighting _lighting(_ble, {{3, true}, {0, false}}, A0);
RFIDReader _rfidReader(_ble, 10, 9);

void setup()
{
  Serial.begin(9600);
  while (!Serial);

  SPI.begin();

  _ble.begin(_runner);
  _matrixR4.begin();
  _lighting.begin(_runner);
  _rfidReader.begin(_runner);
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
