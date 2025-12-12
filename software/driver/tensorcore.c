/**
 * @file tensorcore.c
 * @brief TensorCore Accelerator Driver Implementation
 * 
 * @author TensorCore-FPGA Contributors
 * @license Apache-2.0
 */

#include "tensorcore.h"
#include <stddef.h>

/* For Xilinx standalone BSP */
#ifdef __XILINX__
#include "xil_io.h"
#define REG_READ(addr)       Xil_In32((uint32_t)(addr))
#define REG_WRITE(addr, val) Xil_Out32((uint32_t)(addr), (val))
#else
/* Generic memory-mapped I/O */
#define REG_READ(addr)       (*(volatile uint32_t *)(addr))
#define REG_WRITE(addr, val) (*(volatile uint32_t *)(addr) = (val))
#endif

/* ============================================================================
 * Internal Helpers
 * ============================================================================ */

static inline uint32_t tc_read(TensorCore_t *tc, uint32_t offset)
{
    return REG_READ((uint32_t)tc->base + offset);
}

static inline void tc_write(TensorCore_t *tc, uint32_t offset, uint32_t value)
{
    REG_WRITE((uint32_t)tc->base + offset, value);
}

/* ============================================================================
 * Public API
 * ============================================================================ */

int TensorCore_Init(TensorCore_t *tc, uint32_t base_addr)
{
    if (tc == NULL) {
        return -1;
    }
    
    tc->base = (volatile uint32_t *)base_addr;
    
    /* Reset on init */
    TensorCore_Reset(tc);
    
    return 0;
}

void TensorCore_Reset(TensorCore_t *tc)
{
    tc_write(tc, TENSORCORE_CTRL_OFFSET, TENSORCORE_CTRL_RESET);
    tc_write(tc, TENSORCORE_CTRL_OFFSET, 0);
}

void TensorCore_Configure(TensorCore_t *tc, uint8_t k1, uint8_t k2, uint8_t k3)
{
    tc_write(tc, TENSORCORE_K1_OFFSET, k1);
    tc_write(tc, TENSORCORE_K2_OFFSET, k2);
    tc_write(tc, TENSORCORE_K3_OFFSET, k3);
}

void TensorCore_SetAddresses(TensorCore_t *tc, uint16_t a_base, uint16_t w_base, uint16_t c_base)
{
    tc_write(tc, TENSORCORE_A_BASE_OFFSET, a_base);
    tc_write(tc, TENSORCORE_W_BASE_OFFSET, w_base);
    tc_write(tc, TENSORCORE_C_BASE_OFFSET, c_base);
}

void TensorCore_SetVpuOp(TensorCore_t *tc, uint8_t op)
{
    tc_write(tc, TENSORCORE_VPU_OP_OFFSET, op);
}

void TensorCore_Start(TensorCore_t *tc, bool vpu_enable, bool output_stationary)
{
    uint32_t ctrl = TENSORCORE_CTRL_START;
    
    if (vpu_enable) {
        ctrl |= TENSORCORE_CTRL_VPU_ENABLE;
    }
    if (output_stationary) {
        ctrl |= TENSORCORE_CTRL_MODE;
    }
    
    tc_write(tc, TENSORCORE_CTRL_OFFSET, ctrl);
}

bool TensorCore_IsDone(TensorCore_t *tc)
{
    uint32_t status = tc_read(tc, TENSORCORE_STATUS_OFFSET);
    return (status & TENSORCORE_STATUS_DONE) != 0;
}

bool TensorCore_IsBusy(TensorCore_t *tc)
{
    uint32_t status = tc_read(tc, TENSORCORE_STATUS_OFFSET);
    return (status & TENSORCORE_STATUS_BUSY) != 0;
}

int TensorCore_WaitDone(TensorCore_t *tc, uint32_t timeout_us)
{
    uint32_t elapsed = 0;
    const uint32_t poll_interval = 10;  /* 10us */
    
    while (!TensorCore_IsDone(tc)) {
        if (timeout_us > 0 && elapsed >= timeout_us) {
            return -1;  /* Timeout */
        }
        
        /* Simple delay (platform-specific) */
        #ifdef __XILINX__
        usleep(poll_interval);
        #else
        volatile int i;
        for (i = 0; i < 100; i++);  /* ~10us on typical ARM */
        #endif
        
        elapsed += poll_interval;
    }
    
    return 0;
}

uint8_t TensorCore_GetState(TensorCore_t *tc)
{
    uint32_t status = tc_read(tc, TENSORCORE_STATUS_OFFSET);
    return (status & TENSORCORE_STATUS_STATE_MASK) >> TENSORCORE_STATUS_STATE_SHIFT;
}

uint32_t TensorCore_GetPerfCycles(TensorCore_t *tc)
{
    return tc_read(tc, TENSORCORE_PERF_CYC_OFFSET);
}

uint32_t TensorCore_GetPerfMemReads(TensorCore_t *tc)
{
    return tc_read(tc, TENSORCORE_PERF_RD_OFFSET);
}

uint32_t TensorCore_GetPerfMemWrites(TensorCore_t *tc)
{
    return tc_read(tc, TENSORCORE_PERF_WR_OFFSET);
}
