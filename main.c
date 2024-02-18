
#include "defs.h"
// pipelineC doesn't do headers properly, so we include
// functions by including the whole source file
#include "fip.c"
#include "mem.c"
#include "shading.c"
#include "ray_intersect_tri.c"

// For testing, return bv array so we can display a value from it on hex.
Vct_3d main()
{
    bv_array_9_t BV = read_all_bvs(0, 9);
    Triangle tri1;
    Ray ray1;
    ray1.origin[0] = 6;
    ray1.origin[1] = 3;
    ray1.origin[2] = 8;

    ray1.dir[0] = 5;
    ray1.dir[1] = 2;
    ray1.dir[2] = 37;

    tri1.v1[0] = 99;
    tri1.v1[1] = 33;
    tri1.v1[2] = 28;

    tri1.v2[0] = 23;
    tri1.v2[1] = 32;
    tri1.v2[2] = 66;

    tri1.v3[0] = 52;
    tri1.v3[1] = 17;
    tri1.v3[2] = 61;

    ray_intersect_tri(tri1, ray1);
    __clk(); // indicates that BV is a reg

    Ray ray;
    ray.dir[0] = BV.data[0].cmin[0];
    ray.dir[1] = BV.data[0].cmin[1];
    ray.dir[2] = BV.data[0].cmin[2];
    ray.origin[0] = BV.data[0].cmax[0];
    ray.origin[1] = BV.data[0].cmax[1];
    ray.origin[2] = BV.data[0].cmax[2];

    Vct_3d temp = new_blinn_phong_shading(
        BV.data[1].cmax[2],
        ray,
        BV.data[1].cmin[0], // hit distance
        BV.data[1].cmin[1],
        BV.data[1].cmin[2],
        BV.data[1].cmax[0],
        BV.data[1].cmax[1]
    );
    return temp;
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
    topout.hex[0] = (uint4_t)(o.return_output.var[0] & 0xF);
    
    return topout;
}
