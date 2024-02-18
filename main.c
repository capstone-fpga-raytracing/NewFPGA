
#include "defs.h"
// pipelineC doesn't do headers properly, so we include
// functions by including the whole source file
#include "mem.c"

// For testing, return bv array so we can display a value from it on hex.
bv_array_9_t main()
{
    bv_array_9_t BV = read_all_bvs(0, 9);
    __clk(); // indicates that BV is a reg
    return BV;
}

// this indicates that main() is a stateful function i.e. an FSM.
// read_all_bvs() is also a stateful function, but it is only called by
// main() and only the top most FSM needs to be declared this way (I think).
// see wiki/FSM-Style.
#include "main_FSM.h"

// Top level module inputs
typedef struct top_in
{
    avmm_in avin;
    uint1_t start;
    // add more if needed
} top_in;

// Top level module outputs
typedef struct top_out
{
    avmm_out avout;
    uint4_t hex[6];
    uint1_t hex_valid;
    // add more if needed
} top_out;

#pragma MAIN_MHZ top 100.0 // clock freq
top_out top(top_in topin)
{
    top_out topout;
    // sets up all the avalon_sdr signals
    // as global variables. See mem.c
    topout.avout = setup_avalon_sdr(topin.avin);

    // boilerplate to call main
    // main()'s return value is stored in o.return_output
    // see wiki/FSM-Style
    main_INPUT_t i;
    i.input_valid = topin.start;
    i.output_ready = 1;
    main_OUTPUT_t o = main_FSM(i);
    
    // show first byte on hex0
    topout.hex_valid = o.output_valid;
    topout.hex[0] = (uint4_t)(o.return_output.data[0].cmin[0] & 0xF);
    
    return topout;
}
