"""
TensorCore-FPGA PYNQ Driver

Python driver for controlling the TensorCore accelerator on PYNQ.
Provides high-level API for matrix operations and VPU functions.

Usage:
    from pynq import Overlay
    from tensorcore import TensorCoreDriver
    
    overlay = Overlay("tensorcore.bit")
    tc = TensorCoreDriver(overlay)
    
    tc.configure(k1=4, k2=4, k3=4)
    tc.start()
    tc.wait_done()
    print(f"Cycles: {tc.perf_cycles}")
"""

import numpy as np
from typing import Optional, Tuple


# =============================================================================
# Fixed-Point Conversion Utilities (Q16.16 format)
# =============================================================================

def float_to_q16_16(value: float) -> int:
    """Convert float to Q16.16 fixed-point representation."""
    return int(value * 65536) & 0xFFFFFFFF

def q16_16_to_float(value: int) -> float:
    """Convert Q16.16 fixed-point to float."""
    # Handle signed 32-bit
    if value >= 0x80000000:
        value = value - 0x100000000
    return value / 65536.0

def array_to_q16_16(arr: np.ndarray) -> np.ndarray:
    """Convert numpy array to Q16.16 fixed-point (as uint32)."""
    return (arr * 65536).astype(np.int32).view(np.uint32)

def q16_16_to_array(arr: np.ndarray) -> np.ndarray:
    """Convert Q16.16 fixed-point array back to float."""
    signed = arr.view(np.int32)
    return signed.astype(np.float32) / 65536.0


class TensorCoreDriver:
    """
    Driver for TensorCore accelerator on PYNQ-Z1.
    
    Register Map:
        0x00: CTRL     - Control register
        0x04: STATUS   - Status register
        0x08: K1       - Matrix dimension K1
        0x0C: K2       - Matrix dimension K2
        0x10: K3       - Matrix dimension K3
        0x14: A_BASE   - Matrix A base address
        0x18: W_BASE   - Matrix W base address
        0x1C: C_BASE   - Matrix C base address
        0x20: PERF_CYC - Performance: cycles
        0x24: PERF_RD  - Performance: memory reads
        0x28: PERF_WR  - Performance: memory writes
        0x2C: VPU_OP   - VPU operation select
    """
    
    # Register offsets
    REG_CTRL     = 0x00
    REG_STATUS   = 0x04
    REG_K1       = 0x08
    REG_K2       = 0x0C
    REG_K3       = 0x10
    REG_A_BASE   = 0x14
    REG_W_BASE   = 0x18
    REG_C_BASE   = 0x1C
    REG_PERF_CYC = 0x20
    REG_PERF_RD  = 0x24
    REG_PERF_WR  = 0x28
    REG_VPU_OP   = 0x2C
    
    # Control register bits
    CTRL_START      = 0x01
    CTRL_RESET      = 0x02
    CTRL_VPU_ENABLE = 0x04
    CTRL_MODE       = 0x08
    
    # Status register bits
    STATUS_DONE = 0x01
    STATUS_BUSY = 0x02
    
    # VPU operations
    VPU_OP_NORM    = 0
    VPU_OP_SOFTMAX = 1
    
    def __init__(self, overlay, ip_name: str = "tensorcore_0"):
        """
        Initialize TensorCore driver.
        
        Args:
            overlay: PYNQ Overlay object with loaded bitstream
            ip_name: Name of TensorCore IP in block design
        """
        self.overlay = overlay
        
        # Get MMIO handle for register access
        try:
            self.ip = getattr(overlay, ip_name)
            self.mmio = self.ip.mmio
        except AttributeError:
            # Fallback: direct MMIO at known address
            from pynq import MMIO
            self.mmio = MMIO(0x43C00000, 0x1000)
        
        # Reset on init
        self.reset()
    
    def _read_reg(self, offset: int) -> int:
        """Read 32-bit register."""
        return self.mmio.read(offset)
    
    def _write_reg(self, offset: int, value: int):
        """Write 32-bit register."""
        self.mmio.write(offset, value)
    
    # =========================================================================
    # Control Methods
    # =========================================================================
    
    def reset(self):
        """Reset the accelerator."""
        self._write_reg(self.REG_CTRL, self.CTRL_RESET)
        self._write_reg(self.REG_CTRL, 0)
    
    def start(self, vpu_enable: bool = False, output_stationary: bool = False):
        """
        Start computation.
        
        Args:
            vpu_enable: Enable VPU post-processing
            output_stationary: Use output stationary dataflow
        """
        ctrl = self.CTRL_START
        if vpu_enable:
            ctrl |= self.CTRL_VPU_ENABLE
        if output_stationary:
            ctrl |= self.CTRL_MODE
        self._write_reg(self.REG_CTRL, ctrl)
    
    def wait_done(self, timeout_ms: int = 10000) -> bool:
        """
        Wait for computation to complete.
        
        Args:
            timeout_ms: Timeout in milliseconds
            
        Returns:
            True if completed, False if timeout
        """
        import time
        start_time = time.time()
        timeout_sec = timeout_ms / 1000.0
        
        while (time.time() - start_time) < timeout_sec:
            if self.is_done:
                return True
            time.sleep(0.001)  # 1ms poll interval
        
        return False
    
    @property
    def is_done(self) -> bool:
        """Check if computation is complete."""
        return bool(self._read_reg(self.REG_STATUS) & self.STATUS_DONE)
    
    @property
    def is_busy(self) -> bool:
        """Check if accelerator is busy."""
        return bool(self._read_reg(self.REG_STATUS) & self.STATUS_BUSY)
    
    @property
    def state(self) -> int:
        """Get current FSM state (bits 7:4 of status)."""
        return (self._read_reg(self.REG_STATUS) >> 4) & 0x0F
    
    # =========================================================================
    # Configuration Methods
    # =========================================================================
    
    def configure(self, k1: int, k2: int, k3: int,
                  a_base: int = 0, w_base: int = 0x1000, c_base: int = 0x2000):
        """
        Configure matrix dimensions and base addresses.
        
        Matrix A: K1 x K2
        Matrix W: K2 x K3
        Matrix C: K1 x K3 (output)
        
        Args:
            k1: Rows of A, rows of C
            k2: Cols of A, rows of W
            k3: Cols of W, cols of C
            a_base: Base address for matrix A
            w_base: Base address for matrix W
            c_base: Base address for matrix C
        """
        self._write_reg(self.REG_K1, k1 & 0xFF)
        self._write_reg(self.REG_K2, k2 & 0xFF)
        self._write_reg(self.REG_K3, k3 & 0xFF)
        self._write_reg(self.REG_A_BASE, a_base & 0xFFFF)
        self._write_reg(self.REG_W_BASE, w_base & 0xFFFF)
        self._write_reg(self.REG_C_BASE, c_base & 0xFFFF)
    
    def set_vpu_operation(self, op: int):
        """
        Set VPU operation.
        
        Args:
            op: 0 for L2 Normalization, 1 for Softmax
        """
        self._write_reg(self.REG_VPU_OP, op & 0xFF)
    
    # =========================================================================
    # Performance Counters
    # =========================================================================
    
    @property
    def perf_cycles(self) -> int:
        """Get total cycle count."""
        return self._read_reg(self.REG_PERF_CYC)
    
    @property
    def perf_mem_reads(self) -> int:
        """Get memory read count."""
        return self._read_reg(self.REG_PERF_RD)
    
    @property
    def perf_mem_writes(self) -> int:
        """Get memory write count."""
        return self._read_reg(self.REG_PERF_WR)
    
    def get_performance(self) -> dict:
        """
        Get all performance counters.
        
        Returns:
            Dictionary with cycle, read, and write counts
        """
        return {
            "cycles": self.perf_cycles,
            "mem_reads": self.perf_mem_reads,
            "mem_writes": self.perf_mem_writes
        }
    
    # =========================================================================
    # DMA and Buffer Management
    # =========================================================================
    
    def allocate_buffers(self, max_dim: int = 16):
        """
        Allocate contiguous DMA buffers for matrix operations.
        
        Args:
            max_dim: Maximum matrix dimension to support
            
        Note: This allocates physically contiguous memory that can be
        accessed by both PS and PL. The buffers persist until explicitly freed.
        """
        from pynq import allocate
        
        # Calculate buffer sizes (Q16.16 = 4 bytes per element)
        max_elements = max_dim * max_dim
        
        # Allocate buffers for A, W, and C matrices
        self.buf_A = allocate(shape=(max_dim, max_dim), dtype=np.uint32)
        self.buf_W = allocate(shape=(max_dim, max_dim), dtype=np.uint32)
        self.buf_C = allocate(shape=(max_dim, max_dim), dtype=np.uint32)
        
        # Store physical addresses for PL access
        self.phys_addr_A = self.buf_A.device_address
        self.phys_addr_W = self.buf_W.device_address
        self.phys_addr_C = self.buf_C.device_address
        
        self._buffers_allocated = True
        self._max_dim = max_dim
        
        return self.buf_A, self.buf_W, self.buf_C
    
    def free_buffers(self):
        """Free allocated DMA buffers."""
        if hasattr(self, '_buffers_allocated') and self._buffers_allocated:
            self.buf_A.freebuffer()
            self.buf_W.freebuffer()
            self.buf_C.freebuffer()
            self._buffers_allocated = False
    
    def write_matrix_to_bram(self, matrix: np.ndarray, base_addr: int):
        """
        Write matrix to accelerator's internal BRAM via MMIO.
        
        Args:
            matrix: Input numpy array (float or Q16.16 uint32)
            base_addr: Base address offset in BRAM
            
        Note: This writes directly to the on-chip BRAM mapped in the PL.
        For larger matrices, consider using external DDR with AXI DMA.
        """
        # Convert to Q16.16 if needed
        if matrix.dtype in [np.float32, np.float64]:
            data = array_to_q16_16(matrix.astype(np.float32))
        else:
            data = matrix.astype(np.uint32)
        
        # Flatten and write word by word
        flat = data.flatten()
        for i, val in enumerate(flat):
            # Write to memory via MMIO extension (if available)
            # For now, this is a placeholder - real implementation
            # depends on memory-mapped BRAM interface
            pass
        
        return len(flat)
    
    def read_matrix_from_bram(self, rows: int, cols: int, base_addr: int) -> np.ndarray:
        """
        Read matrix from accelerator's internal BRAM via MMIO.
        
        Args:
            rows: Number of rows
            cols: Number of columns
            base_addr: Base address offset in BRAM
            
        Returns:
            numpy array in float format
        """
        # Placeholder - real implementation depends on memory interface
        result = np.zeros((rows, cols), dtype=np.uint32)
        return q16_16_to_array(result)
    
    # =========================================================================
    # High-Level Operations
    # =========================================================================
    
    def matmul(self, A: np.ndarray, W: np.ndarray, 
               vpu_op: Optional[int] = None) -> Tuple[np.ndarray, dict]:
        """
        Perform matrix multiplication C = A @ W.
        
        Args:
            A: Input matrix (K1 x K2) as float numpy array
            W: Weight matrix (K2 x K3) as float numpy array
            vpu_op: Optional VPU post-processing (0=Norm, 1=Softmax)
            
        Returns:
            Tuple of (result matrix, performance dict)
            
        Note: Current implementation runs computation in accelerator but
        returns software-computed result (DMA data path not yet connected).
        """
        k1, k2 = A.shape
        k2_w, k3 = W.shape
        
        assert k2 == k2_w, f"Dimension mismatch: A.cols={k2}, W.rows={k2_w}"
        assert k1 <= 255 and k2 <= 255 and k3 <= 255, "Dimensions must be <= 255"
        
        # Reset before new computation
        self.reset()
        
        # Configure dimensions
        self.configure(k1, k2, k3)
        
        if vpu_op is not None:
            self.set_vpu_operation(vpu_op)
        
        # Start accelerator
        self.start(vpu_enable=(vpu_op is not None))
        
        # Wait for completion
        success = self.wait_done()
        
        if not success:
            raise TimeoutError("TensorCore computation timed out")
        
        # Get performance metrics
        perf = self.get_performance()
        
        # Compute result in software (until DMA data path is connected)
        # The accelerator is running but we can't read results yet
        C = A @ W
        
        return C, perf
    
    def benchmark(self, sizes: list = [2, 4, 8, 16]) -> dict:
        """
        Run benchmark across different matrix sizes.
        
        Args:
            sizes: List of matrix dimensions to test
            
        Returns:
            Dictionary with size -> cycles mapping
        """
        results = {}
        
        for size in sizes:
            self.reset()
            self.configure(size, size, size)
            self.start()
            self.wait_done()
            results[size] = self.perf_cycles
            
        return results
    
    def __repr__(self) -> str:
        status = "BUSY" if self.is_busy else ("DONE" if self.is_done else "IDLE")
        return f"TensorCoreDriver(status={status}, state={self.state})"
    
    def __del__(self):
        """Cleanup: free buffers when driver is deleted."""
        self.free_buffers()

