# ============================================================================
# build.tcl - Vivado Batch & GUI Build Script for RealDigital Urbana Lock
# Usage:
#   Batch: vivado -mode batch -source scripts/build.tcl
#   GUI:   Tools > Run Tcl Script -> select scripts/build.tcl
# ============================================================================

# Automatically resolve the project root and all source paths
set script_dir [file dirname [file normalize [info script]]]
set proj_root  [file normalize "$script_dir/.."]
cd $proj_root

# Close any project currently open in Vivado GUI to prevent conflicts
if {[current_project -quiet] ne ""} {
    puts "============================================================"
    puts "Closing currently open project [current_project]..."
    puts "============================================================"
    close_project
}

set proj "digital_lock_proj"
set part "xc7s50csga324-1"

puts "============================================================"
puts "Project Root Directory: $proj_root"
puts "Creating Vivado Project ($proj) for part $part..."
puts "============================================================"

# Create clean project directory
create_project -force $proj [file normalize "$proj_root/vivado_proj"] -part $part

# Absolute file paths (guarantees files are found in any directory or GUI mode)
set rtl_files [list \
    [file normalize "$proj_root/rtl/digital_lock.v"] \
    [file normalize "$proj_root/rtl/sev_seg_display.v"] \
    [file normalize "$proj_root/rtl/digital_lock_top.v"] \
]
set xdc_file [file normalize "$proj_root/constr/urbana_digital_lock.xdc"]
set sim_file [file normalize "$proj_root/sim/tb_digital_lock.v"]

# Add design sources
add_files $rtl_files
add_files -fileset constrs_1 $xdc_file
add_files -fileset sim_1     $sim_file

# Configure top-level modules
set_property top digital_lock_top [get_filesets sources_1]
set_property top tb_digital_lock  [get_filesets sim_1]
update_compile_order -fileset sources_1

# --- 1. Behavioral Simulation ---
puts "============================================================"
puts "Step 1: Running Behavioral Simulation (tb_digital_lock)..."
puts "============================================================"
launch_simulation
run all
close_sim

# --- 2. Synthesis ---
puts "============================================================"
puts "Step 2: Running Synthesis..."
puts "============================================================"
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis Status: $synth_status"
if {$synth_status != "synth_design Complete!"} {
    error "Synthesis failed! Inspect vivado_proj/$proj.runs/synth_1/runme.log for details."
}

# --- 3. Implementation and Bitstream ---
puts "============================================================"
puts "Step 3: Running Implementation & Bitstream Generation..."
puts "============================================================"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation Status: $impl_status"
if {$impl_status != "write_bitstream Complete!"} {
    error "Implementation / Bitstream generation failed! Inspect vivado_proj/$proj.runs/impl_1/runme.log"
}

# --- 4. Post-Implementation Timing & Utilization Reports ---
puts "============================================================"
puts "Step 4: Generating Timing and Utilization Reports..."
puts "============================================================"
open_run impl_1
report_timing_summary -file ./vivado_proj/timing_summary.rpt
report_utilization    -file ./vivado_proj/utilization.rpt

set bitstream_path [file normalize "./vivado_proj/$proj.runs/impl_1/digital_lock_top.bit"]
puts "============================================================"
puts "BUILD COMPLETE!"
puts "Bitstream generated at:"
puts "  $bitstream_path"
puts "============================================================"
