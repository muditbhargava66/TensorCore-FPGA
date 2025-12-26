`ifndef SYSTEM_DEFS_VH
`define SYSTEM_DEFS_VH

// =================================================================
// System-Level Definitions
// =================================================================

// Systolic Array Dimensions (Tile Size)
`define SA_ROWS 3
`define SA_COLS 3

// Memory Configuration
`define ADDR_WIDTH 16
`define DATA_WIDTH 64
`define MEM_SIZE   65536

// Vector Processing Unit
`define VPU_VECTOR_SIZE 32

// States
`define STATE_IDLE 4'd0
`define STATE_INIT 4'd1
`define STATE_READ_A 4'd2
`define STATE_READ_W 4'd3
`define STATE_COMPUTE 4'd4
`define STATE_WRITE_C 4'd5
`define STATE_NEXT_TILE 4'd6
`define STATE_DONE 4'd7

`endif // SYSTEM_DEFS_VH
