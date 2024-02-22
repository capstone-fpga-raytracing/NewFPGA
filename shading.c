#include "defs.h"

#define FIP_AMB 0x00002000 // 0.125

Vct_3d new_blinn_phong_shading(
    int32_t hit_tri_id,
    Ray_t ray,
    int32_t t, // hit distance
    int32_t num_lights,
    uint32_t lights_addr,
    uint32_t mats_addr,
    uint32_t verts_addr
) {
    // read vert
    int32_t vert_id = 9 * hit_tri_id;
    int288_t vert_array;
    while (!sdr_readend) {
        sdr_baseaddr = verts_addr + vert_id;
        sdr_nelems = 9;
        sdr_readstart = !sdr_readend;
        vert_array = (int288_t)(sdr_readdata);
        __clk();
    }
    Vert vert;

    // read mat
    int32_t mat_id = MATS_ELEM_SIZE * hit_tri_id;
    int288_t mat_array;
    while (!sdr_readend) {
        sdr_baseaddr = mats_addr + mat_id;
        sdr_nelems = 9;
        sdr_readstart = !sdr_readend;
        mat_array = (int288_t)(sdr_readdata);
        __clk();
    }
    Material mat;

    // normal
    int32_t edge0[3] = {vert.v1[0] - vert.v0[0],
                        vert.v1[1] - vert.v0[1],
                        vert.v1[2] - vert.v0[2]};
    int32_t edge1[3] = {vert.v2[0] - vert.v0[0],
                        vert.v2[1] - vert.v0[1],
                        vert.v2[2] - vert.v0[2]};

    Vct_3d normal_raw;
    normal_raw.var[0] = fip_mult(edge0[1], edge1[2]) - fip_mult(edge0[2], edge1[1]);
    normal_raw.var[1] = fip_mult(edge0[2], edge1[0]) - fip_mult(edge0[0], edge1[2]);
    normal_raw.var[2] = fip_mult(edge0[0], edge1[1]) - fip_mult(edge0[1], edge1[0]);

    Vct_3d normal = fip_normalize(normal_raw);

    // hit point
    int32_t hit_point[3];
    hit_point[0] = ray.origin[0] + fip_mult(t, ray.dir[0]);
    hit_point[1] = ray.origin[1] + fip_mult(t, ray.dir[1]);
    hit_point[2] = ray.origin[2] + fip_mult(t, ray.dir[2]);

    // ambient
    Vct_3d total_light;
    total_light.var[0] = fip_mult(mat.ka[0], FIP_AMB);
    total_light.var[1] = fip_mult(mat.ka[1], FIP_AMB);
    total_light.var[2] = fip_mult(mat.ka[2], FIP_AMB);

    // shadow, diffuse and specular
    for (int32_t light_id = 0; light_id < num_lights; light_id+=1) {
        // read light
        int192_t light_array;
        while (!sdr_readend) {
            sdr_baseaddr = lights_addr + light_id;
            sdr_nelems = 9;
            sdr_readstart = !sdr_readend;
            light_array = (int192_t)(sdr_readdata);
            __clk();
        }
        Light light;
        
        // direction
        Vct_3d dir_raw;
        dir_raw.var[0] = light.src[0] - hit_point[0];
        dir_raw.var[1] = light.src[1] - hit_point[1];
        dir_raw.var[2] = light.src[2] - hit_point[2];
        Vct_3d dir = fip_normalize(dir_raw);

        // shadow: ignored for now

        // diffuse
        int32_t diff_light_term = MAX(fip_mult(normal.var[0], dir.var[0]) +
                                      fip_mult(normal.var[1], dir.var[1]) +
                                      fip_mult(normal.var[2], dir.var[2]), 0);
        int32_t diff_light[3];
        diff_light[0] = fip_mult(diff_light_term, fip_mult(mat.kd[0], light.color[0]));
        diff_light[1] = fip_mult(diff_light_term, fip_mult(mat.kd[1], light.color[1]));
        diff_light[2] = fip_mult(diff_light_term, fip_mult(mat.kd[2], light.color[2]));

        // specular: ignored for now

        // update total_light
        total_light.var[0] += diff_light[0];
        total_light.var[1] += diff_light[1];
        total_light.var[2] += diff_light[2];
    }
    
    // chop off light >= 1
    total_light.var[0] = MIN(total_light.var[0], FIP_ALMOST_ONE);
    total_light.var[1] = MIN(total_light.var[1], FIP_ALMOST_ONE);
    total_light.var[2] = MIN(total_light.var[2], FIP_ALMOST_ONE);

    return total_light;
}
