# RISCV-Vector-Processor
Characteristics of the implementation :

1. VLEN=32, VSEW=32, Vm bit=1 (unmasked),16 ALU lanes, 16 elements could be loaded/stored from/to memory into/from the vector register per clock cycle.
2. Instructions considered for Unit-Stride and Vector Integer Arithmetic operations.
3. Fetch and decode done in the same cycle.
4. Memory access stage for Arithmetic instructions is ignored as memory will not be accessed.
