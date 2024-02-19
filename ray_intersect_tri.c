#include "defs.h"

ritri_out ray_intersect_tri(const Triangle tri, const Ray ray1)
{
    // solve the system by Cramer's rule:
    // [T1, T2, -D] |a|
    //              |b| = E - P0, where
    //              |t|
    // Triangle = aT1 + bT2 + P0 for a >= 0, b >=0, a + b <= 1.

	ritri_out out;
	out.t = 0;
	out.flag = 0;
    
    int32_t v[3][3];
    v[0] = tri.v1;
    v[1] = tri.v2;
    v[2] = tri.v3;

    int32_t sys[4][3];
    //     { v[1][0] - v[0][0], v[1][1] - v[0][1], v[1][2] - v[0][2] }, // vert[1] - vert[0]
    //     { v[2][0] - v[0][0], v[2][1] - v[0][1], v[2][2] - v[0][2] }, // vert[2] - vert[0]
    //     { -ray1.dir[0], -ray1.dir[1], -ray1.dir[2] }, // -ray1.dir
    //     { ray1.origin[0] - v[0][0], ray1.origin[1] - v[0][1], ray1.origin[2] - v[0][2] } // ray1.origin - vert[0]
    // };

    sys[0][0] = v[1][0] - v[0][0];
    sys[0][1] = v[1][1] - v[0][1];
    sys[0][2] = v[1][2] - v[0][2];

    sys[1][0] = v[2][0] - v[0][0];
    sys[1][1] = v[2][1] - v[0][1];
    sys[1][2] = v[2][2] - v[0][2];

    sys[2][0] = -ray1.dir[0];
    sys[2][1] = -ray1.dir[1];
    sys[2][2] = -ray1.dir[2];

    sys[3][0] = ray1.origin[0] - v[0][0];
    sys[3][1] = ray1.origin[1] - v[0][1];
    sys[3][2] = ray1.origin[2] - v[0][2];

    Vert vert0;
    vert0.v0 = sys[0];
    vert0.v1 = sys[1];
    vert0.v2 = sys[2];

    int32_t det_coeffs = fip_det(vert0);
    if (det_coeffs == 0){ // no unique soln (very unlikely)
        out.flag = 0;
	} 
    else{
        Vert vert1, vert2, vert3;

        vert1.v0 = sys[3];
        vert1.v1 = sys[1];
        vert1.v2 = sys[2];

        vert2.v0 = sys[0];
        vert2.v1 = sys[3];
        vert2.v2 = sys[2];

        vert3.v0 = sys[0];
        vert3.v1 = sys[1];
        vert3.v2 = sys[3];


        int32_t a = fip_sat_div(fip_det(vert1), det_coeffs);
        int32_t b = fip_sat_div(fip_det(vert2), det_coeffs);
        int32_t t = fip_sat_div(fip_det(vert3), det_coeffs);

        int32_t res = fip_sat_add(a,b);
        if (a >= 0 && b >= 0 && res <= FIP_ONE && t >= 0)
        {
            out.t = t;
            out.flag = 1;
        }
        else out.flag = 0;
    }
	return out;
}