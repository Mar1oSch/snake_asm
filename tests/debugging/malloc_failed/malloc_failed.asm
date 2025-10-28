global malloc_failed

section .rodata
    debug_string db "Error in %s-Function. Expectet a pointer but got: %d.", 13, 10, 0

section .text
    extern printf

malloc_failed:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    ; Expect pointer to constructor_name in RCX.
    ; Expect failed malloc-return in RDX.
    mov r8, rdx
    mov rdx, rcx
    lea rcx, [rel debug_string]
    call printf

    mov rsp, rbp
    pop rbp
    ret