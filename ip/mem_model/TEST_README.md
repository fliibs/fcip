# Memory Model Test Suite

## Overview
This directory contains comprehensive behavioral models and tests for SPRAM (Single-Port RAM) and DPRAM (Dual-Port RAM).

## Files Structure

### Memory Models
- `fcip_spram_model.sv` - Single-port SRAM behavioral model with hex file loading support
- `fcip_dpram_model.sv` - Dual-port SRAM behavioral model with independent read/write ports

### Test Infrastructure
- `test/fcip_spram_simple_tb.sv` - SPRAM testbench (4 test phases)
- `test/fcip_dpram_simple_tb.sv` - DPRAM testbench (4 test phases)
- `test/verilator_main.cpp` - C++ driver for SPRAM (generates clock)
- `test/verilator_main_dpram.cpp` - C++ driver for DPRAM (generates clock)
- `test/spram_init.hex` - SPRAM initialization data
- `test/dpram_init.hex` - DPRAM initialization data

## Test Coverage

### SPRAM Test (Phase 0-3)
1. **Phase 0: HEX File Load Test** - Verifies correct loading of 10 addresses from hex file
2. **Phase 1: Write and Read Test** - Basic write/read functionality
3. **Phase 2: Mask Write Test** - Selective byte/word write operations
4. **Phase 3: Multiple Read/Write** - Sequential read/write operations

### DPRAM Test (Phase 0-3)
1. **Phase 0: HEX File Load Test** - Verifies correct loading of 10 addresses from hex file
2. **Phase 1: Independent Read/Write** - Read from one address while writing to another
3. **Phase 2: Mask Write Test** - Selective write operations
4. **Phase 3: Simultaneous Read/Write** - True simultaneous read/write on independent ports

## Building and Testing

### Prerequisites
- Verilator 5.042 or later
- GCC 12.3.0 or later (C++20 support required for --timing mode)
- Linux environment

### Running Tests

```bash
# Run SPRAM test
make test_spram

# Run DPRAM test
make test_dpram

# Run both tests
make test_spram test_dpram

# Verify models compile
make comp

# Clean build artifacts
make clean
```

## Key Features

### Memory Models
- **Parameterizable**: ADDR_WIDTH, DATA_WIDTH configurable
- **Hex Loading**: Support for Motorola format hex files via +HEX_FILE=<path>
- **Masked Write**: Bit-level write masking via wr_bit_en signal
- **Verilator Compatible**: Uses blocking assignments for associative arrays
- **Timing Simulation**: Full support for --timing mode with delay modeling

### Test Harness
- **C++ Clock Generation**: Eliminates testbench timing code, cleaner SystemVerilog
- **Event-Based Synchronization**: Uses @(posedge clk) and @(negedge clk) for clean sequencing
- **GCC 12 + C++20**: Enables full timing simulation with proper C++ coroutine support
- **Comprehensive Coverage**: 4 phases per memory type testing various scenarios

## Known Limitations

None at this time. All tests pass successfully with Verilator --timing mode.

## Future Enhancements

- Add parameterized test data generation
- Add random access pattern testing
- Add performance metrics collection
