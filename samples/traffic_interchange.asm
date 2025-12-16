# Complex Traffic Interchange Simulation
# Simulates a 4-way junction with:
# - North-South (NS) road
# - East-West (EW) road  
# - Left turn lanes
# - Pedestrian crossings
# - Emergency vehicle priority
# Uses memory to store traffic states and timing

# Memory layout:
# MEM[0] = NS main road timer
# MEM[4] = EW main road timer
# MEM[8] = NS left turn timer
# MEM[12] = EW left turn timer
# MEM[16] = Pedestrian crossing timer
# MEM[20] = Current phase (0=NS, 1=EW, 2=NS-left, 3=EW-left, 4=pedestrian)
# MEM[24] = Emergency mode flag (0=normal, 1=emergency)
# MEM[28] = Cycle counter

init:
    # Initialize constants
    SET R15, 1          # Constant 1
    SET R14, 5          # Main road green duration
    SET R13, 3          # Left turn duration
    SET R12, 2          # Pedestrian crossing duration
    SET R11, 10         # Emergency override duration
    
    # Initialize memory values
    SET R1, 0           # Base address
    SET R2, 5           # NS timer = 5
    SW R2, 0(R1)        # MEM[0] = 5
    SET R2, 5           # EW timer = 5
    SW R2, 4(R1)        # MEM[4] = 5
    SET R2, 3           # NS-left timer = 3
    SW R2, 8(R1)        # MEM[8] = 3
    SET R2, 3           # EW-left timer = 3
    SW R2, 12(R1)       # MEM[12] = 3
    SET R2, 2           # Pedestrian timer = 2
    SW R2, 16(R1)       # MEM[16] = 2
    SET R2, 0           # Phase = 0 (NS)
    SW R2, 20(R1)       # MEM[20] = 0
    SET R2, 0           # Emergency = 0
    SW R2, 24(R1)       # MEM[24] = 0
    SET R2, 0           # Cycle counter = 0
    SW R2, 28(R1)       # MEM[28] = 0

main_loop:
    # Load current phase
    LW R10, 20(R1)      # R10 = current phase
    OUT 0, R10          # Output current phase to port 0
    
    # Check for emergency mode (simulated - check if cycle counter == 50)
    LW R9, 28(R1)       # R9 = cycle counter
    SET R8, 50          # Check value
    BEQ R9, R8, emergency_mode
    J normal_operation
    
emergency_mode:
    # Emergency: all red except one direction
    SET R6, 1           # Emergency flag
    SW R6, 24(R1)       # MEM[24] = 1
    SET R6, 4           # Emergency phase
    SW R6, 20(R1)       # MEM[20] = 4
    OUT 1, R6           # Output emergency signal
    SET R6, 10          # Emergency duration
    SW R6, 16(R1)       # Use pedestrian timer for emergency
    J phase_pedestrian
    
normal_operation:
    # Phase 0: NS main road
    BEQ R10, R0, phase_ns
    SET R6, 1
    BEQ R10, R6, phase_ew
    SET R6, 2
    BEQ R10, R6, phase_ns_left
    SET R6, 3
    BEQ R10, R6, phase_ew_left
    J phase_pedestrian
    
phase_ns:
    # North-South main road green
    LW R9, 0(R1)        # R9 = NS timer
    SUB R9, R9, R15     # Decrement timer
    SW R9, 0(R1)        # Store back
    BEQ R9, R0, next_phase_ns
    J update_cycle
    
next_phase_ns:
    # Move to NS left turn
    SET R9, 2           # Phase 2
    SW R9, 20(R1)       # MEM[20] = 2
    SW R13, 8(R1)       # Reset NS-left timer to 3
    J update_cycle
    
phase_ew:
    # East-West main road green
    LW R9, 4(R1)        # R9 = EW timer
    SUB R9, R9, R15     # Decrement timer
    SW R9, 4(R1)        # Store back
    BEQ R9, R0, next_phase_ew
    J update_cycle
    
next_phase_ew:
    # Move to EW left turn
    SET R9, 3           # Phase 3
    SW R9, 20(R1)       # MEM[20] = 3
    SW R13, 12(R1)      # Reset EW-left timer to 3
    J update_cycle
    
phase_ns_left:
    # NS left turn
    LW R9, 8(R1)        # R9 = NS-left timer
    SUB R9, R9, R15     # Decrement timer
    SW R9, 8(R1)        # Store back
    BEQ R9, R0, next_phase_ns_left
    J update_cycle
    
next_phase_ns_left:
    # Move to EW main
    SET R9, 1           # Phase 1
    SW R9, 20(R1)       # MEM[20] = 1
    SW R14, 4(R1)       # Reset EW timer to 5
    J update_cycle
    
phase_ew_left:
    # EW left turn
    LW R9, 12(R1)       # R9 = EW-left timer
    SUB R9, R9, R15     # Decrement timer
    SW R9, 12(R1)       # Store back
    BEQ R9, R0, next_phase_ew_left
    J update_cycle
    
next_phase_ew_left:
    # Move to pedestrian crossing
    SET R9, 4           # Phase 4
    SW R9, 20(R1)       # MEM[20] = 4
    SW R12, 16(R1)      # Reset pedestrian timer to 2
    J update_cycle
    
phase_pedestrian:
    # Pedestrian crossing
    LW R9, 16(R1)       # R9 = pedestrian timer
    SUB R9, R9, R15     # Decrement timer
    SW R9, 16(R1)       # Store back
    BEQ R9, R0, next_phase_pedestrian
    J update_cycle
    
next_phase_pedestrian:
    # Check emergency flag
    LW R8, 24(R1)       # R8 = emergency flag
    BEQ R8, R0, reset_to_ns
    # Clear emergency
    SET R8, 0
    SW R8, 24(R1)       # MEM[24] = 0
    
reset_to_ns:
    # Cycle back to NS main
    SET R9, 0           # Phase 0
    SW R9, 20(R1)       # MEM[20] = 0
    SW R14, 0(R1)       # Reset NS timer to 5
    J update_cycle
    
update_cycle:
    # Increment cycle counter
    LW R9, 28(R1)       # R9 = cycle counter
    ADD R9, R9, R15     # Increment
    SW R9, 28(R1)       # Store back
    
    # Output traffic state to port 2
    LW R8, 20(R1)       # R8 = current phase
    OUT 2, R8           # Output phase
    
    # Output timer value to port 3 (current phase timer)
    BEQ R8, R0, out_ns_timer
    SET R7, 1
    BEQ R8, R7, out_ew_timer
    SET R7, 2
    BEQ R8, R7, out_ns_left_timer
    SET R7, 3
    BEQ R8, R7, out_ew_left_timer
    J out_ped_timer
    
out_ns_timer:
    LW R7, 0(R1)
    OUT 3, R7
    J main_loop
    
out_ew_timer:
    LW R7, 4(R1)
    OUT 3, R7
    J main_loop
    
out_ns_left_timer:
    LW R7, 8(R1)
    OUT 3, R7
    J main_loop
    
out_ew_left_timer:
    LW R7, 12(R1)
    OUT 3, R7
    J main_loop
    
out_ped_timer:
    LW R7, 16(R1)
    OUT 3, R7
    J main_loop

