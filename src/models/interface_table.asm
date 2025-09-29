%include "../include/interface_table_struc.inc"

global interface_table_new, interface_table_destroy

section .rodata
    constructor_name db "interface_table_new", 0

section .text
    extern malloc
    extern free
    extern malloc_failed

interface_table_new:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    ; Expect pointer to vtable_drawable in RCX.
    ; 0 if there is none.
    mov qword [rbp - 8], rcx

    mov rcx, interface_table_size
    call malloc
    test rax, rax
    jz .failed

    mov rcx, [rbp - 8]
    mov qword [rax + interface_table.vtable_drawable_ptr], rcx

    mov rsp, rbp
    pop rbp
    ret

.failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret

interface_table_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to INTERFACE_TABLE object in RCX.
    call free

    mov rsp, rbp
    pop rbp
    ret