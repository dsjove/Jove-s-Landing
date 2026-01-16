#include "Lighting.h"

static Lighting* lightingRef = NULL;

Lighting::Lighting(BLEServiceRunner& ble, std::vector<LightOutput> output, int sensor)
: _output(output)
, _sensor(sensor)
, _currentPower(0)
, _currentCalibration(255)
, _currentAmbient(0)
, _currentSignal(0)
, _powerControlChar(ble.characteristic("03020001", (uint8_t*)NULL, updatePower))
, _powerFeedbackChar(ble.characteristic("03020002", &_currentPower))
, _calibrationChar(ble.characteristic("03010000", &_currentCalibration, updateCalibration))
, _sensedFeedbackChar(ble.characteristic("03040002", &_currentAmbient, sensor != -1 ? updateSensed : NULL))
, _lightingTask(1000, TASK_FOREVER, &senseAmbient_task)
{
  lightingRef = this;
}

void Lighting::begin(Scheduler& scheduler)
{
  for (LightOutput light : _output)
  {  
    pinMode(light.pin, OUTPUT);
  }
  if (_sensor != -1)
  {
    scheduler.addTask(_lightingTask);
    _lightingTask.enable();
   }
}

void Lighting::updatePower(BLEDevice, BLECharacteristic characteristic)
{
  characteristic.readValue(lightingRef->_currentPower);
  lightingRef->update();
}

void Lighting::updateCalibration(BLEDevice, BLECharacteristic characteristic)
{
  characteristic.readValue(lightingRef->_currentCalibration);
  lightingRef->update();
}

void Lighting::senseAmbient_task()
{
  int sensorValue = analogRead(lightingRef->_sensor);
  uint8_t signal = map(sensorValue, 920, 1014, 0, 255);
  if (signal != lightingRef->_currentAmbient)
  {
    lightingRef->_currentAmbient = signal;
    lightingRef->_sensedFeedbackChar.characteristic.writeValue(lightingRef->_currentAmbient);
    lightingRef->update();
  }
}

void Lighting::updateSensed(BLEDevice, BLECharacteristic characteristic) {
  characteristic.readValue(lightingRef->_currentAmbient);
  lightingRef->update();
}

void Lighting::update() {
  uint8_t signal;
  if (_currentCalibration == 0 || _currentCalibration < _currentAmbient)
  {
      signal = 0;
  }
  else
  {
      signal = _currentPower;
  }

  if (signal != _currentSignal)
  {
    _powerFeedbackChar.characteristic.writeValue(signal);
    _currentSignal = signal;

  for (LightOutput light : _output)
  {
      if (light.dimmable)
      {
        analogWrite(light.pin, signal);
      }
      else
      {
        digitalWrite(light.pin, signal);
      }
    }
  }
}
