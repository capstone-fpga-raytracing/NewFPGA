# set the working dir, where all compiled verilog goes
# DO NOT CHANGE
vlib work


# compile rtl
# === CHANGE HERE ===
# vlog ../*.sv

vlog ../div4832_syn.v
vlog ../divider.sv
vlog ../fip_opts.sv
vlog ../cache.sv
vlog ../avalon_sdr.sv
vlog ../reader.sv
vlog ../intersection.sv
vlog ../raytracer.sv
vlog ../shading.sv



# compile testbench
# === CHANGE HERE ===
# vlog *.sv

vlog fip_opts_tb.sv
vlog cache_tb.sv
vlog reader_tb.sv
vlog intersection_tb.sv
vlog raytracer_tb.sv
# vlog shading_tb.sv

vlog divider_tb.sv



# load top level simulation module
# === CHANGE HERE ===

# vsim fip_32_add_sat_tb
# vsim fip_32_mult_tb
# vsim fip_32_div_tb
# vsim fip_32_vector_cross_tb
# vsim fip_32_vector_dot_tb
# vsim fip_32_sqrt_tb
# vsim fip_32_3b3_det_tb
# vsim fip_32_vector_normal_tb

# vsim cache_ro_tb
# vsim cache_ro_multi_tb
# vsim reader_tb
# vsim intersection_tb
# vsim tri_insector_tb
vsim raytracer_tb
# vsim bp_shading_tb
# vsim bp_shading_light_tb
#vsim divider_tb



# log all signals
log {/*}

# add all items in top level simulation module
add wave {/*}

# simulate
run -all

# quit -sim
