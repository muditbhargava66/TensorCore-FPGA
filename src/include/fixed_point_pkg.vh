`ifndef FIXED_POINT_PKG_VH
`define FIXED_POINT_PKG_VH

// =============================================================================
// Fixed-Point Arithmetic Package for HAI Processor
// =============================================================================
// Format: Q16.16 (32-bit signed, 16 integer bits, 16 fractional bits)
// Range: -32768.0 to +32767.99998 (approximately)
// Resolution: 1/65536 ≈ 0.000015
// =============================================================================

// Data width definitions
`define FP_WIDTH       32
`define FP_INT_BITS    16
`define FP_FRAC_BITS   16

// Conversion macros (for testbench/simulation)
// To convert: value * 65536 (2^16)
`define FP_ONE         32'h00010000  // 1.0
`define FP_HALF        32'h00008000  // 0.5
`define FP_ZERO        32'h00000000  // 0.0
`define FP_NEG_ONE     32'hFFFF0000  // -1.0

// For accumulator, use wider width to prevent overflow
`define FP_ACC_WIDTH   48
`define FP_ACC_FRAC    16

// MAC output needs extra bits for accumulation
`define MAC_ACC_WIDTH  48

`endif // FIXED_POINT_PKG_VH
