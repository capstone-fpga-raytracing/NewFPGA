// #include "../defs.h"
// #include "../fip.c"
// #define sys[0] tri.v2[0] - tri.v1[0], tri.v2[1] - tri.v1[1], tri.v2[2] - tri.v1[2]
// #define sys[1] tri.v3[0] - tri.v1[0], tri.v3[1] - tri.v1[1], tri.v3[2] - tri.v1[2]
// #define sys[2] -ray.dir[0], -ray.dir[1], -ray.dir[2]
// #define sys[3] ray.origin[0] - tri.v1[0], ray.origin[1] - tri.v1[1], ray.origin[2] - tri.v1[2]

// typedef struct ritri_out {
// 	int32_t t;
// 	uint1_t flag; // Intersect bool
// } ritri_out;

// ritri_out ray_intersect_tri(Triangle_t tri, Ray_t ray)
// {
//     // solve the system by Cramer's rule:
//     // [T1, T2, -D] |a|
//     //              |b| = E - P0, where
//     //              |t|
//     // Triangle = aT1 + bT2 + P0 for a >= 0, b >=0, a + b <= 1.

// 	ritri_out out_st;
// 	out_st.t = 0;
// 	out_st.flag = 0;
    
//     // Vct_3d_t sys[4];

//     // sys[0].var[0] = tri.v2[0] - tri.v1[0];
//     // sys[0].var[1] = tri.v2[1] - tri.v1[1];
//     // sys[0].var[2] = tri.v2[2] - tri.v1[2];

//     // sys[1].var[0] =tri.v3[0] - tri.v1[0];
//     // sys[1].var[1] =tri.v3[1] - tri.v1[1];
//     // sys[1].var[2] =tri.v3[2] - tri.v1[2];

//     // sys[2].var[0] = -ray.dir[0];
//     // sys[2].var[1] = -ray.dir[1];
//     // sys[2].var[2] = -ray.dir[2];

//     // sys[3].var[0] = ray.origin[0] - tri.v1[0];
//     // sys[3].var[1] = ray.origin[1] - tri.v1[1];
//     // sys[3].var[2] = ray.origin[2] - tri.v1[2];

//     int32_t det_coeffs = fip_det(sys[0], sys[1], sys[2]);
//     if (det_coeffs == 0){ // no unique soln (very unlikely)
//         out_st.flag = 0;
// 	} 
//     else{

//         int32_t a = fip_sat_div(fip_det(sys[3], sys[1], sys[2]), det_coeffs);
//         int32_t b = fip_sat_div(fip_det(sys[0], sys[3], sys[2]), det_coeffs);
//         int32_t t = fip_sat_div(fip_det(sys[0], sys[1], sys[3]), det_coeffs);

//         int32_t res = fip_sat_add(a,b);
//         if (a >= 0 && b >= 0 && res <= FIP_ONE && t >= 0)
//         {
//             out_st.t = t;
//             out_st.flag = 1;
//         }
//         else out_st.flag = 0;
//     }
// 	return out_st;
// }

#include "../defs.h"
#include "../fip.c"

typedef struct ritri_out {
    int32_t t;
    uint1_t flag; // Intersect bool
} ritri_out;

ritri_out ray_intersect_tri(Triangle_t tri, Ray_t ray)
{
    ritri_out out_st;
    out_st.t = 0;
    out_st.flag = 0;

    // Calculate the determinants directly with the provided values
    int32_t det_coeffs = 2;//fip_det(
    //     tri.v2[0] - tri.v1[0], tri.v2[1] - tri.v1[1], tri.v2[2] - tri.v1[2], // sys[0]
    //     tri.v3[0] - tri.v1[0], tri.v3[1] - tri.v1[1], tri.v3[2] - tri.v1[2], // sys[1]
    //     -ray.dir[0], -ray.dir[1], -ray.dir[2] // sys[2]
    // );

    if (det_coeffs == 0) { // no unique solution (very unlikely)
        out_st.flag = 0;
    } else {
        int32_t a = 5;//fip_det(
        //     ray.origin[0] - tri.v1[0], ray.origin[1] - tri.v1[1], ray.origin[2] - tri.v1[2], // sys[3] as first vector
        //     tri.v3[0] - tri.v1[0], tri.v3[1] - tri.v1[1], tri.v3[2] - tri.v1[2], // sys[1]
        //     -ray.dir[0], -ray.dir[1], -ray.dir[2] // sys[2]
        // );

        int32_t b = 6;//fip_det(
        //     tri.v2[0] - tri.v1[0], tri.v2[1] - tri.v1[1], tri.v2[2] - tri.v1[2], // sys[0]
        //     ray.origin[0] - tri.v1[0], ray.origin[1] - tri.v1[1], ray.origin[2] - tri.v1[2], // sys[3] as second vector
        //     -ray.dir[0], -ray.dir[1], -ray.dir[2] // sys[2]
        // );

        int32_t t = 2; //fip_det(
        //     tri.v2[0] - tri.v1[0], tri.v2[1] - tri.v1[1], tri.v2[2] - tri.v1[2], // sys[0]
        //     tri.v3[0] - tri.v1[0], tri.  v3[1] - tri.v1[1], tri.v3[2] - tri.v1[2], // sys[1]
        //     ray.origin[0] - tri.v1[0], ray.origin[1] - tri.v1[1], ray.origin[2] - tri.v1[2] // sys[3] as third vector
        // );

        int32_t res = fip_sat_add(a, b);
        if (a >= 0 && b >= 0 && res <= FIP_ONE && t >= 0) {
            out_st.t = t;
            out_st.flag = 1;
        } else {
            out_st.flag = 0;
        }
    }
    return out_st;
}


#pragma MAIN_MHZ rt_top 50.0 // clock freq
// Top level module inputs
typedef struct rt_top_in
{
    Ray_t ray;
    Triangle_t tri;
} rt_top_in;
typedef struct rt_top_out
{
    ritri_out output;
} rt_top_out;

rt_top_out rt_top(rt_top_in rt_in)
{
    rt_top_out rt_out;
    rt_out.output = ray_intersect_tri(rt_in.tri, rt_in.ray);
    return rt_out;
}