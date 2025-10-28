- Why are X- and Y-coordinates swapped?
- Why is there an interface_table, if there is just one interface in the whole project?
- Why interface at all and not the objects themself?
- How handling the stack? 
  1. rbp-x = local variables
  2. sub rsp 32 = creating shadow space for function calls.
  3. Using shadow space to rescue in regs passed arguments.