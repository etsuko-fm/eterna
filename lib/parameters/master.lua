ID_MASTER_MONO_FREQ = "master_mono_freq"
ID_MASTER_COMP_DRIVE = "master_comp_drive"
ID_MASTER_COMP_AMOUNT = "master_comp_amount"
-- ID_MASTER_OUTPUT = "master_output"

BASS_MONO_FREQS_STR = {"OFF", "50Hz", "100Hz", "200Hz", "FULL"}
BASS_MONO_FREQS_INT = {20, 50, 100, 200, 20000}

COMP_AMOUNTS = {"OFF", "SOFT", "MEDIUM", "HARD"}

params:add_separator("MASTER", "MASTER")
params:add_option(ID_MASTER_MONO_FREQ, "bass mono freq", BASS_MONO_FREQS_STR, 2)
-- params:add_control(ID_MASTER_COMP_DRIVE, "compressor drive", controlspec_master_drive)
params:add_option(ID_MASTER_COMP_AMOUNT, "compressor amount", COMP_AMOUNTS, 2)
-- params:add_control(ID_MASTER_OUTPUT, "output", controlspec_master_output)

