/**
 * @file tensorcore.h
 * @brief TensorCore Accelerator Driver for Bare-Metal/Vitis
 * 
 * Register-level driver for controlling TensorCore LLM accelerator
 * on Xilinx Zynq platforms.
 * 
 * @author TensorCore-FPGA Contributors
 * @license Apache-2.0
 */

#ifndef TENSORCORE_H
#define TENSORCORE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * Base Address (from Vivado block design)
 * ============================================================================ */
#define TENSORCORE_BASE_ADDR    0x43C00000

/* ============================================================================
 * Register Offsets
 * ============================================================================ */
#define TENSORCORE_CTRL_OFFSET      0x00
#define TENSORCORE_STATUS_OFFSET    0x04
#define TENSORCORE_K1_OFFSET        0x08
#define TENSORCORE_K2_OFFSET        0x0C
#define TENSORCORE_K3_OFFSET        0x10
#define TENSORCORE_A_BASE_OFFSET    0x14
#define TENSORCORE_W_BASE_OFFSET    0x18
#define TENSORCORE_C_BASE_OFFSET    0x1C
#define TENSORCORE_PERF_CYC_OFFSET  0x20
#define TENSORCORE_PERF_RD_OFFSET   0x24
#define TENSORCORE_PERF_WR_OFFSET   0x28
#define TENSORCORE_VPU_OP_OFFSET    0x2C

/* ============================================================================
 * Control Register Bits
 * ============================================================================ */
#define TENSORCORE_CTRL_START       (1 << 0)
#define TENSORCORE_CTRL_RESET       (1 << 1)
#define TENSORCORE_CTRL_VPU_ENABLE  (1 << 2)
#define TENSORCORE_CTRL_MODE        (1 << 3)  /* 0=WS, 1=OS */

/* ============================================================================
 * Status Register Bits
 * ============================================================================ */
#define TENSORCORE_STATUS_DONE      (1 << 0)
#define TENSORCORE_STATUS_BUSY      (1 << 1)
#define TENSORCORE_STATUS_STATE_MASK (0xF << 4)
#define TENSORCORE_STATUS_STATE_SHIFT 4

/* ============================================================================
 * VPU Operations
 * ============================================================================ */
#define TENSORCORE_VPU_OP_NORM      0
#define TENSORCORE_VPU_OP_SOFTMAX   1

/* ============================================================================
 * Driver Handle
 * ============================================================================ */
typedef struct {
    volatile uint32_t *base;  /**< Base address of register space */
} TensorCore_t;

/* ============================================================================
 * Function Prototypes
 * ============================================================================ */

/**
 * @brief Initialize TensorCore driver
 * @param tc Pointer to driver instance
 * @param base_addr Base address of TensorCore registers
 * @return 0 on success, -1 on error
 */
int TensorCore_Init(TensorCore_t *tc, uint32_t base_addr);

/**
 * @brief Reset the accelerator
 * @param tc Pointer to driver instance
 */
void TensorCore_Reset(TensorCore_t *tc);

/**
 * @brief Configure matrix dimensions
 * @param tc Pointer to driver instance
 * @param k1 Rows of A / rows of C
 * @param k2 Cols of A / rows of W
 * @param k3 Cols of W / cols of C
 */
void TensorCore_Configure(TensorCore_t *tc, uint8_t k1, uint8_t k2, uint8_t k3);

/**
 * @brief Configure memory base addresses
 * @param tc Pointer to driver instance
 * @param a_base Base address for matrix A
 * @param w_base Base address for matrix W
 * @param c_base Base address for matrix C
 */
void TensorCore_SetAddresses(TensorCore_t *tc, uint16_t a_base, uint16_t w_base, uint16_t c_base);

/**
 * @brief Set VPU operation type
 * @param tc Pointer to driver instance
 * @param op Operation (TENSORCORE_VPU_OP_NORM or TENSORCORE_VPU_OP_SOFTMAX)
 */
void TensorCore_SetVpuOp(TensorCore_t *tc, uint8_t op);

/**
 * @brief Start computation
 * @param tc Pointer to driver instance
 * @param vpu_enable Enable VPU post-processing
 * @param output_stationary Use output stationary dataflow
 */
void TensorCore_Start(TensorCore_t *tc, bool vpu_enable, bool output_stationary);

/**
 * @brief Check if computation is complete
 * @param tc Pointer to driver instance
 * @return true if done, false otherwise
 */
bool TensorCore_IsDone(TensorCore_t *tc);

/**
 * @brief Check if accelerator is busy
 * @param tc Pointer to driver instance
 * @return true if busy, false otherwise
 */
bool TensorCore_IsBusy(TensorCore_t *tc);

/**
 * @brief Wait for computation to complete (blocking)
 * @param tc Pointer to driver instance
 * @param timeout_us Timeout in microseconds (0 = infinite)
 * @return 0 on success, -1 on timeout
 */
int TensorCore_WaitDone(TensorCore_t *tc, uint32_t timeout_us);

/**
 * @brief Get current FSM state
 * @param tc Pointer to driver instance
 * @return State value (0-15)
 */
uint8_t TensorCore_GetState(TensorCore_t *tc);

/**
 * @brief Get performance: cycle count
 * @param tc Pointer to driver instance
 * @return Number of cycles since start
 */
uint32_t TensorCore_GetPerfCycles(TensorCore_t *tc);

/**
 * @brief Get performance: memory read count
 * @param tc Pointer to driver instance
 * @return Number of memory reads
 */
uint32_t TensorCore_GetPerfMemReads(TensorCore_t *tc);

/**
 * @brief Get performance: memory write count
 * @param tc Pointer to driver instance
 * @return Number of memory writes
 */
uint32_t TensorCore_GetPerfMemWrites(TensorCore_t *tc);

#ifdef __cplusplus
}
#endif

#endif /* TENSORCORE_H */
