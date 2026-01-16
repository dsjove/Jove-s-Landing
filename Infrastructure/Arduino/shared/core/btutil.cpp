#include "btutil.h"
#include <array>
#include <string>
#include <algorithm>

namespace btutil
{
BLEUUID makeUuidWithService(
    const std::string& serviceName,
    const std::string& overrideId)
{
  BLEUUID result;
  if (!overrideId.empty())
  {
    std::copy_n(overrideId.begin(), 37, result.begin());
  }
  else
  {
    result.fill('0');
    result[8] = '-';
    result[37] = 0;
    int pos = 9;
    for (size_t i = 0; i < 12 && i < serviceName.length(); i++) {
      sprintf(result.data() + pos, "%02X", serviceName[i]);
      pos+=2;
      if (i == 1 || i == 3 || i == 5)
      {
         result[pos] = '-';
         pos+=1;
      }
    }
  }
  return result;
}

BLEUUID makeUuidWithProperty(
    const std::string& propertyId,
    const BLEUUID& serviceId)
{
  BLEUUID out {};
  std::copy_n(serviceId.begin(), 36, out.begin());
  std::copy_n(propertyId.begin(), 8, out.begin());
  out[36] = '\0';
  return out;
}

unsigned char adjustPermissions(
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
