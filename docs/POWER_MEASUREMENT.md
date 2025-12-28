# FPGA Power Measurement Guide

## Using INA219 Current Sensor

### Hardware Setup

```
PYNQ-Z1         INA219          Power Supply
--------        ------          ------------
VIN ─────────── V+ ◄──── (+) ◄── 5V
GND ─────────── GND ◄──── (-) ◄── GND
I2C_SDA ─────── SDA
I2C_SCL ─────── SCL
                V- ────────────► PYNQ VIN
```

### Required Components
- INA219 breakout (Adafruit/generic)
- PYNQ I2C PMOD or GPIO
- Jumper wires

---

## Software Setup

### Install Library
```bash
pip install adafruit-circuitpython-ina219
```

### Python Script
```python
import board
import busio
from adafruit_ina219 import INA219

# Initialize I2C
i2c = busio.I2C(board.SCL, board.SDA)
ina = INA219(i2c)

# Idle measurement
print(f"Idle: {ina.power:.1f} mW")

# Load overlay and run
from pynq import Overlay
ol = Overlay('tensorcore.bit')

# Active measurement
print(f"Active: {ina.power:.1f} mW")
```

---

## Expected Power Consumption

| State | Current | Power |
|-------|---------|-------|
| Idle (no bitstream) | ~250 mA | 1.25 W |
| Bitstream loaded | ~350 mA | 1.75 W |
| Active computation | ~450 mA | 2.25 W |

### Dynamic Power (TensorCore only)
- 2x2 Array: ~50 mW
- 4x4 Array: ~150 mW

---

## Power Efficiency

| Metric | Value |
|--------|-------|
| GOPS/W (2x2) | 16 |
| GOPS/W (4x4) | 21 |

**Comparison:**
- Raspberry Pi 4 (CPU): ~1 GOPS/W
- TensorCore FPGA: ~20 GOPS/W
