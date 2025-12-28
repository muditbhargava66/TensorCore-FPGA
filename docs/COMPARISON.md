# TensorCore vs GPU/TPU Comparison

## Architecture Comparison

| Feature | TensorCore | NVIDIA GPU | Google TPU |
|---------|------------|------------|------------|
| **Array Type** | Systolic 2x2/4x4 | CUDA Cores + Tensor Cores | Systolic 128x128 |
| **Data Type** | INT8 | FP16/INT8/TF32 | BF16/INT8 |
| **On-chip SRAM** | ~2 KB | ~20 MB L2 | 32 MB HBM |
| **Power** | ~2 W | 250-400 W | 450 W |
| **Target** | Edge/TinyTapeout | Data Center | Data Center |

---

## Performance Comparison (4×4 GEMM)

| Platform | Latency | Power | Efficiency |
|----------|---------|-------|------------|
| **TensorCore (FPGA)** | 0.5 µs | 2 W | 16 GOPS/W |
| **NVIDIA RTX 4090** | 0.01 µs | 450 W | 1.7 TOPS/W |
| **Google TPU v4** | 0.001 µs | 450 W | 2.0 TOPS/W |
| **ARM Cortex-A9** | 50 µs | 2 W | 0.01 GOPS/W |

---

## Use Case Positioning

### TensorCore FPGA
✅ Edge deployment  
✅ Low power (~2W)  
✅ Custom silicon (TinyTapeout)  
✅ Real-time inference  
❌ Large models  

### NVIDIA GPU
✅ Training large models  
✅ High throughput  
✅ Mature ecosystem  
❌ Power hungry  
❌ Expensive  

### Google TPU
✅ Massive throughput  
✅ Optimized for transformers  
❌ Cloud-only  
❌ Expensive  

---

## Cost Comparison

| Platform | Unit Cost | Power Cost/Year |
|----------|-----------|-----------------|
| TensorCore (PYNQ-Z1) | $150 | $1.75 |
| TensorCore (TinyTapeout) | $50 | $0.50 |
| NVIDIA RTX 4090 | $1,600 | $400 |
| Google TPU v4 (cloud) | ~$3/hr | N/A |

---

## When to Use TensorCore

| Scenario | Recommendation |
|----------|----------------|
| TinyML on edge | ✅ TensorCore |
| Training LLMs | ❌ Use GPU/TPU |
| Real-time vision | ✅ TensorCore |
| Research prototype | ✅ TensorCore |
| Production at scale | ❌ Use Cloud TPU |

---

## Key Takeaways

1. **TensorCore excels at edge/embedded** - Low power, low cost
2. **GPUs dominate training** - Mature ecosystem, high throughput
3. **TPUs optimized for inference** - Best TOPS/W at scale
4. **TinyTapeout enables custom ASIC** - Ultimate power efficiency
