global INTERFACE_VTABLE_DRAWABLE_OFFSET, INTERFACE_VTABLE_FOOD_OFFSET
global interface_table_new, interface_table_destroy

section .rodata
interface_table:
    INTERFACE_VTABLE_DRAWABLE_OFFSET equ 0
    INTERFACE_VTABLE_FOOD_OFFSET equ 8
interface_table_end:
    INTERFACE_TABLE_SIZE equ interface_table_end - interface_table

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
    ; Expect pointer to vtable_food in RDX.
    ; 0 if there is none.
    mov qword [rbp - 8], rcx
    mov qword [rbp - 16], rdx

    mov rcx, INTERFACE_TABLE_SIZE
    call malloc
    test rax, rax
    jz .failed

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    mov qword [rax + INTERFACE_VTABLE_DRAWABLE_OFFSET], rcx
    mov qword [rax + INTERFACE_VTABLE_FOOD_OFFSET], rdx

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