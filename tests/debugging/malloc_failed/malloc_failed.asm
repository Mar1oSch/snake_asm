global malloc_failed

section .rodata
    debug_string db "Error in %s-Function. Expectet a pointer but got: %d.", 13, 10, 0

section .text
    extern printf

malloc_failed:
    ; Expect pointer to constructor_name in RCX.
    ; Expect failed malloc-return in RDX.
    push rbp
    mov rbp, rsp
    sub rsp, 56

    mov qword [rbp - 8], rcx
    mov qword [rbp - 16], rdx

    lea rcx, [rel debug_string]
    mov rdx, [rbp - 8]
    mov r8, [rbp - 16]
    call printf

    mov rsp, rbp
    pop rbp
    ret