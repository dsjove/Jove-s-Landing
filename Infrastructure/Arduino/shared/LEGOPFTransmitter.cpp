#include "LEGOPFTransmitter.h"

static LEGOPFTransmitter* pfTranbsmitterRef = NULL;

LEGOPFTransmitter::LEGOPFTransmitter(BLEServiceRunner& ble, int pin)
: _pin(pin)
, _transmitChar(ble.characteristic("05020000", 3, NULL, transmit))
{
  for (int i = 0; i < 4; i++) { _gA[i] = 0; _gB[i] = 0; }
  pfTranbsmitterRef = this;
}

void LEGOPFTransmitter::begin()
{
  //pinMode(_pin, OUTPUT);
  //digitalWrite(_pin, LOW);
}

// ===================== User wiring =====================
static const uint8_t IR_PIN = 9;   // D9 -> DFR0095 SIG

// ===================== LEGO PF IR timing =====================
// We generate a 38kHz carrier by toggling the pin.
// (PF protocol uses 38kHz, and "mark" is 6 cycles of carrier.) :contentReference[oaicite:11]{index=11}
static const uint16_t HALF_PERIOD_US = 13;      // ~38kHz half period
static const uint16_t MARK_CYCLES = 6;          // mark length
static const uint16_t PAUSE0_CYCLES = 10;
static const uint16_t PAUSE1_CYCLES = 21;
static const uint16_t PAUSE_STARTSTOP_CYCLES = 39;

// ===================== PF command model =====================
enum class PFPort : uint8_t { A = 0, B = 1 };

// value is the *raw PF PWM nibble* 0..15 (full range). :contentReference[oaicite:12]{index=12}
struct PFCommand {
  uint8_t channel;  // 1..4
  PFPort  port;     // A or B
  uint8_t value;    // 0..15
};

void LEGOPFTransmitter::transmit(BLEDevice, BLECharacteristic characteristic)
{
  std::array<uint8_t, 3> value;
  characteristic.readValue(value.data(), sizeof(value));
  PFCommand command = { value[0], (PFPort)value[1], value[2] };
  pfTranbsmitterRef->transmit(command);
}

void LEGOPFTransmitter::transmit(const PFCommand& command) {
	Serial.println(command.channel);
	Serial.println((int)command.port);
	Serial.println(command.value);
}

// Cache current state because Combo PWM sends A and B together. :contentReference[oaicite:13]{index=13}
static uint8_t gA[4] = {0, 0, 0, 0}; // per channel, Output A value (0..15)
static uint8_t gB[4] = {0, 0, 0, 0}; // per channel, Output B value (0..15)
static bool gToggle = false;         // toggle bit (not verified in Combo modes, but fine to flip) :contentReference[oaicite:14]{index=14}

// ===================== Low-level IR primitives =====================
static inline void delayCycles(uint16_t cycles) {
  delayMicroseconds((uint32_t)cycles * 2U * (uint32_t)HALF_PERIOD_US);
}

static void sendMark6Cycles() {
  for (uint16_t i = 0; i < MARK_CYCLES; i++) {
    digitalWrite(IR_PIN, HIGH);
    delayMicroseconds(HALF_PERIOD_US);
    digitalWrite(IR_PIN, LOW);
    delayMicroseconds(HALF_PERIOD_US);
  }
}

static void sendSymbolWithPause(uint16_t pauseCycles) {
  sendMark6Cycles();
  delayCycles(pauseCycles);
}

static void sendStartOrStop() {
  sendSymbolWithPause(PAUSE_STARTSTOP_CYCLES);
}

static void sendBit(bool one) {
  sendSymbolWithPause(one ? PAUSE1_CYCLES : PAUSE0_CYCLES);
}

static void sendNibbleMSB(uint8_t n) {
  n &= 0x0F;
  sendBit(n & 0x08);
  sendBit(n & 0x04);
  sendBit(n & 0x02);
  sendBit(n & 0x01);
}

// ===================== LEGO PF: Combo PWM packet =====================
// Spec shows Combo PWM mode layout and the 0..15 table for BBBB/AAAA. :contentReference[oaicite:15]{index=15}
static void sendComboPWM(uint8_t channel1to4, uint8_t outB, uint8_t outA) {
  // channel bits are 0..3 representing channel switch 1..4 :contentReference[oaicite:16]{index=16}
  uint8_t ch = (uint8_t)constrain(channel1to4, 1, 4) - 1;

  // From spec: address bit defaults to 0. :contentReference[oaicite:17]{index=17}
  const uint8_t addressBit = 0;

  // Build nibbles for Combo PWM.
  // Spec "Binary representation" for Combo PWM: start a 1 C C BBBB AAAA LLLL stop :contentReference[oaicite:18]{index=18}
  // We'll pack this as:
  // nibble1 = [T E C C] (general format) :contentReference[oaicite:19]{index=19}
  // nibble2 = [a 1 B B] ... and nibble3 etc. are shown differently for Combo PWM,
  // but the practical approach used by hobby implementations is to send:
  //   nib1 = (T,E,CC), nib2 = (a,1, upper bits), nib3 = (lower bits) with LRC over those nibbles.
  //
  // To keep this robust and clear, we will follow the 3-nibble + LRC formula: LRC = 0xF xor n1 xor n2 xor n3. :contentReference[oaicite:20]{index=20}
  //
  // We encode Combo PWM as:
  //   nib1: [T E C C] where E=1 indicates "use special mode" per table (Combo PWM uses the '1' shown). :contentReference[oaicite:21]{index=21}
  //   nib2: [a 1 B3 B2] (top two bits of BBBB)
  //   nib3: [B1 B0 A3 A2] and we then send an extra nibble [A1 A0 0 0]?  -> This gets messy.
  //
  // Instead: use the *exact bit layout* shown for Combo PWM and transmit the full 16-bit payload as nibbles:
  // Payload bits: a 1 C C BBBB AAAA (12 bits) plus LRC (4 bits). :contentReference[oaicite:22]{index=22}
  // We'll construct three nibbles:
  //   N1 = [a 1 C C]
  //   N2 = [B B B B]
  //   N3 = [A A A A]
  //   LRC = 0xF xor N1 xor N2 xor N3 :contentReference[oaicite:23]{index=23}

  gToggle = !gToggle; // harmless here (toggle not verified in this mode) :contentReference[oaicite:24]{index=24}

  uint8_t N1 = (uint8_t)((addressBit << 3) | (1 << 2) | (ch & 0x03)); // [a 1 C C]
  uint8_t N2 = (uint8_t)(outB & 0x0F);                               // BBBB
  uint8_t N3 = (uint8_t)(outA & 0x0F);                               // AAAA
  uint8_t L  = (uint8_t)(0x0F ^ N1 ^ N2 ^ N3);                       // LRC :contentReference[oaicite:25]{index=25}

  sendStartOrStop();
  sendNibbleMSB(N1);
  sendNibbleMSB(N2);
  sendNibbleMSB(N3);
  sendNibbleMSB(L);
  sendStartOrStop();
}

// Apply one {channel,port,value} command and transmit updated state for that channel
static void applyAndSend(const PFCommand& cmd) {
  if (cmd.channel < 1 || cmd.channel > 4) return;
  if (cmd.value > 15) return;

  uint8_t idx = cmd.channel - 1;

  if (cmd.port == PFPort::A) gA[idx] = cmd.value;
  else                      gB[idx] = cmd.value;

  // Send a few repeats for reliability (common practice for IR links)
  for (int i = 0; i < 3; i++) {
    sendComboPWM(cmd.channel, gB[idx], gA[idx]);
    delay(30);
  }
}

// Periodic refresh to avoid IR timeout behavior in timed modes (spec mentions timeouts for some commands). :contentReference[oaicite:26]{index=26}
static void refreshAllChannels() {
  for (uint8_t ch = 1; ch <= 4; ch++) {
    uint8_t idx = ch - 1;
    sendComboPWM(ch, gB[idx], gA[idx]);
    delay(5);
  }
}

// ===================== Example usage =====================
void setup2() {
  pinMode(IR_PIN, OUTPUT);
  digitalWrite(IR_PIN, LOW);

  // Initialize all channels to float both ports
  for (int i = 0; i < 4; i++) { gA[i] = 0; gB[i] = 0; }
}

void loop2() {
  // Example: Channel 1 motor on A full forward (7), lights on B full forward (7)
  applyAndSend(PFCommand{1, PFPort::A, 7});
  applyAndSend(PFCommand{1, PFPort::B, 7});
  delay(300);

  // Example: Channel 2 reverse step 4 on A (table value 12 = backward step 4), B float
  // Backward steps are 9..15 in the table. :contentReference[oaicite:27]{index=27}
  applyAndSend(PFCommand{2, PFPort::A, 12});
  applyAndSend(PFCommand{2, PFPort::B, 0});
  delay(300);

  // Keep refreshing so receivers don't time out in timed modes. :contentReference[oaicite:28]{index=28}
  refreshAllChannels();
  delay(150);
}
