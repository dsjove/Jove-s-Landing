#include "LegoPFIR.h"

LegoPFIR::LegoPFIR(uint8_t irPin)
: _irPin(irPin) {
  for (uint8_t i = 0; i < 4; i++) {
    _a[i] = 0;
    _b[i] = 0;
  }
}

void LegoPFIR::begin() {
  pinMode(_irPin, OUTPUT);
  digitalWrite(_irPin, LOW);
}

bool LegoPFIR::apply(const Command& cmd, uint8_t repeats, uint16_t repeatDelayMs) {
  if (cmd.channel < 1 || cmd.channel > 4) return false;
  if (cmd.value > 15) return false;

  const uint8_t idx = cmd.channel - 1;
  if (cmd.port == Port::A)
    _a[idx] = cmd.value;
  else
    _b[idx] = cmd.value;

  return sendChannel(cmd.channel, repeats, repeatDelayMs);
}

bool LegoPFIR::sendChannel(uint8_t channel, uint8_t repeats, uint16_t repeatDelayMs) {
  if (channel < 1 || channel > 4) return false;

  const uint8_t idx = channel - 1;
  for (uint8_t i = 0; i < repeats; i++) {
    sendComboPWM(channel, _b[idx], _a[idx]);
    if (repeatDelayMs) delay(repeatDelayMs);
  }
  return true;
}

void LegoPFIR::refreshAll(uint16_t interChannelDelayMs) {
  for (uint8_t ch = 1; ch <= 4; ch++) {
    (void)sendChannel(ch, 1, 0);
    if (interChannelDelayMs) delay(interChannelDelayMs);
  }
}

uint8_t LegoPFIR::cachedA(uint8_t channel) const {
  if (channel < 1 || channel > 4) return 0;
  return _a[channel - 1];
}

uint8_t LegoPFIR::cachedB(uint8_t channel) const {
  if (channel < 1 || channel > 4) return 0;
  return _b[channel - 1];
}

bool LegoPFIR::setCached(const Command& cmd) {
  if (cmd.channel < 1 || cmd.channel > 4) return false;
  if (cmd.value > 15) return false;

  const uint8_t idx = cmd.channel - 1;
  if (cmd.port == Port::A)
    _a[idx] = cmd.value;
  else
    _b[idx] = cmd.value;

  return true;
}

// ---------- Low-level IR primitives ----------

inline void LegoPFIR::delayCycles(uint16_t cycles) {
  delayMicroseconds((uint32_t)cycles * 2U * (uint32_t)kHalfPeriodUs);
}

void LegoPFIR::sendMark6Cycles() {
  for (uint16_t i = 0; i < kMarkCycles; i++) {
    digitalWrite(_irPin, HIGH);
    delayMicroseconds(kHalfPeriodUs);
    digitalWrite(_irPin, LOW);
    delayMicroseconds(kHalfPeriodUs);
  }
}

void LegoPFIR::sendSymbolWithPause(uint16_t pauseCycles) {
  sendMark6Cycles();
  delayCycles(pauseCycles);
}

void LegoPFIR::sendStartOrStop() {
  sendSymbolWithPause(kPauseStartStopCycles);
}

void LegoPFIR::sendBit(bool one) {
  sendSymbolWithPause(one ? kPause1Cycles : kPause0Cycles);
}

void LegoPFIR::sendNibbleMSB(uint8_t n) {
  n &= 0x0F;
  sendBit(n & 0x08);
  sendBit(n & 0x04);
  sendBit(n & 0x02);
  sendBit(n & 0x01);
}

void LegoPFIR::sendComboPWM(uint8_t channel1to4, uint8_t outB, uint8_t outA) {
  const uint8_t ch = (uint8_t)constrain(channel1to4, 1, 4) - 1; // 0..3
  const uint8_t addressBit = 0; // a=0 for PF IR receivers

  const uint8_t N1 = (uint8_t)((addressBit << 3) | (1 << 2) | (ch & 0x03)); // [a 1 C C]
  const uint8_t N2 = (uint8_t)(outB & 0x0F);                                // BBBB
  const uint8_t N3 = (uint8_t)(outA & 0x0F);                                // AAAA
  const uint8_t L  = (uint8_t)(0x0F ^ N1 ^ N2 ^ N3);                        // LRC

  sendStartOrStop();
  sendNibbleMSB(N1);
  sendNibbleMSB(N2);
  sendNibbleMSB(N3);
  sendNibbleMSB(L);
  sendStartOrStop();
}
