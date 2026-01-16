#pragma once

#include <Arduino.h>

class LegoPFIR {
public:
  enum class Port : uint8_t { A, B };

  // value is raw PF PWM nibble 0..15:
  // 0=float, 1..7=fwd1..fwd7, 8=brake, 9..15=rev7..rev1
  struct Command {
    uint8_t channel; // 1..4
    Port port;       // A or B
    uint8_t value;   // 0..15
  };

  explicit LegoPFIR(uint8_t irPin);

  void begin();

  // Apply one {channel,port,value} command and transmit updated state for that channel.
  // repeats and repeatDelayMs improve reliability.
  // Returns false if inputs invalid.
  bool apply(const Command& cmd, uint8_t repeats = 3, uint16_t repeatDelayMs = 30);

  // Transmit current cached A/B values for a channel (useful as keep-alive).
  bool sendChannel(uint8_t channel, uint8_t repeats = 1, uint16_t repeatDelayMs = 0);

  // Refresh all channels once (recommended periodically, e.g., every 100–300ms)
  void refreshAll(uint16_t interChannelDelayMs = 5);

  // Read cached values (no transmit)
  uint8_t cachedA(uint8_t channel) const;
  uint8_t cachedB(uint8_t channel) const;

  // Set cache without sending (then call sendChannel/refreshAll when ready)
  bool setCached(const Command& cmd);

private:
  // ======== LEGO PF IR timing (38kHz carrier) ========
  static constexpr uint16_t kHalfPeriodUs = 13;          // ~38kHz half period
  static constexpr uint16_t kMarkCycles = 6;             // mark = 6 cycles
  static constexpr uint16_t kPause0Cycles = 10;
  static constexpr uint16_t kPause1Cycles = 21;
  static constexpr uint16_t kPauseStartStopCycles = 39;

  const uint8_t _irPin;
  uint8_t _a[4]; // cached values per channel, Output A
  uint8_t _b[4]; // cached values per channel, Output B

  static inline void delayCycles(uint16_t cycles);

  void sendMark6Cycles();
  void sendSymbolWithPause(uint16_t pauseCycles);
  void sendStartOrStop();
  void sendBit(bool one);
  void sendNibbleMSB(uint8_t n);

  // Combo PWM packet:
  // N1 = [a 1 C C]
  // N2 = BBBB
  // N3 = AAAA
  // L  = 0xF xor N1 xor N2 xor N3
  void sendComboPWM(uint8_t channel1to4, uint8_t outB, uint8_t outA);
};
