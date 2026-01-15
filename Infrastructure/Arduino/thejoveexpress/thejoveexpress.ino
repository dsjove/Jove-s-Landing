#include "shared/core/BLEServiceRunner.cpp"
#include "shared/ServoMotor.cpp"
#include "shared/Lighting.cpp"

#include <TaskScheduler.h>

Scheduler _runner;
BLEServiceRunner _ble("Jove Express");
Lighting _lighting(_ble, {{3, true}, {0, false}}, A0);
ServoMotor _servoMotor(_ble, 9);

void setup()
{
  Serial.begin(9600);
  while (!Serial);

  _ble.begin(_runner);
  _lighting.begin(_runner);
  _servoMotor.begin();
}

void loop()
{
  _runner.execute();
}
