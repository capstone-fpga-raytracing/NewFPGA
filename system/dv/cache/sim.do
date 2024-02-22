# set the working dir, where all compiled verilog goes
# DO NOT CHANGE
vlib work


# compile required verilog modules to working dir
# source files
# vlog ../*.sv
vlog ./test_cache.sv


# testbenches
# vlog *.sv
vlog ./test_cache_tb.sv


# load simulation using the top level simulation module
# === CHANGE HERE ===
# vsim *
vsim cache_ro_tb



# log all signals
log {/*}
log * -r

# add all items in top level simulation module
add wave {/*}
add wave {/cache_ro_inst/*}

# simulate
run -all

# quit -sim