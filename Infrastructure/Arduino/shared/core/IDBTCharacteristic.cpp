// IDBTCharacteristic.cpp
#include "IDBTCharacteristic.h"

#include <array>
#include <string>
#include <algorithm>

namespace btutil {

std::string generateServiceID(const std::string& name, const std::string& serviceID)
{
  std::string result;
  result.reserve(37);
  result.append(8, '0');
  result.push_back('-');

  if (!serviceID.empty()) 
  {
    result.append(serviceID);
  }
  else
  {
    size_t i = 0;
    for (; i < 12 && i < name.length(); i++)
    {
      char output[3];
      sprintf(output, "%02X", name[i]);
      result.append(output);
      if (i == 1 || i == 3 || i == 5)
      {
        result.push_back('-');
      }
    }
    if (i < 12)
    {
      result.append((12 - i) * 2, '0');
    }
  }
  return result;
}

std::array<char, 37> makeUuidWithProperty(
    const std::string& serviceId,
    const std::string& propertyId)
{
    std::array<char, 37> out{};

    // Copy base UUID (36 chars)
    std::copy_n(serviceId.begin(), 36, out.begin());

    // Replace first 8 chars with property ID
    std::copy_n(propertyId.begin(), 8, out.begin());

    // Null terminate
    out[36] = '\0';

    return out;
}

static unsigned char adjustPermissions(
    unsigned char base,
    const void* value,
    BLECharacteristicEventHandler eventHandler)
{
  unsigned char p = base;
  if (eventHandler)
  {
    p |= BLEWriteWithoutResponse;
  }
  if (value) {
    p |= BLERead;
    p |= BLENotify;
  }
  return p;
}

}

IDBTCharacteristic::IDBTCharacteristic(
  const std::string& propertyId,
  const std::string& serviceId,
  int valueSize,
  const void* value,
BLECharacteristicEventHandler eventHandler)
: uuid(btutil::makeUuidWithProperty(propertyId, serviceId))
, characteristic(uuid.data(), btutil::adjustPermissions(0, value, eventHandler), valueSize)
{
  if (eventHandler)
  {
    characteristic.setEventHandler(BLEWritten, eventHandler);
  }
  if (value)
  {
    characteristic.writeValue(static_cast<const unsigned char*>(value), valueSize);
  }
}
