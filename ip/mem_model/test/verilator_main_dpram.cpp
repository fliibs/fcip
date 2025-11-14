#include <verilated.h>
#include "Vfcip_dpram_simple_tb.h"
#include "Vfcip_dpram_simple_tb__Syms.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vfcip_dpram_simple_tb* top = new Vfcip_dpram_simple_tb;

    // Run simulation with clock generation
    int cycle_count = 0;
    const int MAX_CYCLES = 50000;  // Safety limit
    
    while (!Verilated::gotFinish() && cycle_count < MAX_CYCLES) {
        // Generate clock: toggle every cycle
        top->rootp->fcip_dpram_simple_tb__DOT__clk = (cycle_count % 2) == 0 ? 1 : 0;
        top->eval();
        cycle_count++;
    }

    delete top;
    return 0;
}
