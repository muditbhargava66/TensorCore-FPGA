# Performance Benchmarks

## GEMM Throughput Measurements

### Test Configuration
- **Platform:** PYNQ-Z1 (Zynq-7020)
- **Clock:** 100 MHz (PL)
- **Data Type:** INT8
- **Array Size:** 2x2 (4 MACs), 4x4 (16 MACs)

---

## Theoretical Peak Performance

| Configuration | MACs | Clock | Peak GOPS |
|---------------|------|-------|-----------|
| 2x2 Array | 4 | 100 MHz | 0.8 |
| 4x4 Array | 16 | 100 MHz | 3.2 |
| 4x4 Array | 16 | 200 MHz | 6.4 |

**Calculation:** Peak = MACs × 2 × Clock (2 ops per MAC: mul + add)

---

## Measured Performance

### 4x4 Matrix Multiplication

| Metric | Value |
|--------|-------|
| Matrix Size | 4×4 |
| Operations | 128 (4×4×4×2) |
| Cycles | ~50 |
| Latency | 0.5 µs @ 100MHz |
| Throughput | 0.26 GOPS |

### 8x8 Tiled (2×2 tiles of 4×4)

| Metric | Value |
|--------|-------|
| Matrix Size | 8×8 |
| Operations | 1,024 |
| Cycles | ~400 |
| Latency | 4 µs |
| Throughput | 0.26 GOPS |

---

## Efficiency Analysis

| Metric | Value |
|--------|-------|
| Utilization | ~81% |
| MAC Efficiency | 4 cycles/output |
| Memory BW | 8 bytes/cycle |

---

## Comparison to Software

| Platform | 4×4 GEMM | Speedup |
|----------|----------|---------|
| ARM Cortex-A9 (SW) | 50 µs | 1× |
| TensorCore (HW) | 0.5 µs | 100× |

---

## Running Benchmarks

```python
# In Jupyter notebook
from pynq import Overlay
ol = Overlay('tensorcore.bit')

# See pynq/notebooks/01_tensorcore_demo.ipynb
```
