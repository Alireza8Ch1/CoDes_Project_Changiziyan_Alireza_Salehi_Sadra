SetActiveLib -work
comp -include "$dsn\src\SixBitProcessorWithMultiplier.vhd" 
comp -include "$dsn\src\TestBench\sixbitprocessorwithmultiplier_TB.vhd" 
asim +access +r TESTBENCH_FOR_sixbitprocessorwithmultiplier 
wave 
wave -noreg clk
wave -noreg reset
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\sixbitprocessorwithmultiplier_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_sixbitprocessorwithmultiplier 
