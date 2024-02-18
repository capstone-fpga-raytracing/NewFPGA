#include "defs.h"

ritri_out ray_intersect_tri(const int32_t vs[9], const Ray ray)
{
    // solve the system by Cramer's rule:
    // [T1, T2, -D] |a|
    //              |b| = E - P0, where
    //              |t|
    // Triangle = aT1 + bT2 + P0 for a >= 0, b >=0, a + b <= 1.

	ritri_out out;
	out.t = 0;
	out.flag = 0;
    const int32_t v[3][3] = {
        { vs[0], vs[1], vs[2] },
        { vs[3], vs[4], vs[5] },
        { vs[6], vs[7], vs[8] },
    };

    const int32_t sys[4][3] = {
        { v[1][0] - v[0][0], v[1][1] - v[0][1], v[1][2] - v[0][2] }, // vert[1] - vert[0]
        { v[2][0] - v[0][0], v[2][1] - v[0][1], v[2][2] - v[0][2] }, // vert[2] - vert[0]
        { -ray.dir[0], -ray.dir[1], -ray.dir[2] }, // -ray.dir
        { ray.origin[0] - v[0][0], ray.origin[1] - v[0][1], ray.origin[2] - v[0][2] } // ray.origin - vert[0]
    };

    int32_t det_coeffs = fip_det(sys[0], sys[1], sys[2]);
    if (det_coeffs == 0){ // no unique soln (very unlikely)
        out.flag = 0;
		return out;
	}

    int32_t a = fip_sat_div(fip_det(sys[3], sys[1], sys[2]), det_coeffs);
    int32_t b = fip_sat_div(fip_det(sys[0], sys[3], sys[2]), det_coeffs);
    int32_t t = fip_sat_div(fip_det(sys[0], sys[1], sys[3]), det_coeffs);


    if (a >= 0 && b >= 0 && fip_sat_add(a,b) <= FIP_ONE && t >= 0)
    {
        out.t = t;
        out.flag = 1;
    }
    else out.flag = 0;

	return out;
}