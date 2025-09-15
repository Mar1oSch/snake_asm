%include "../include/position_struc.inc"

global position_new, position_destroy

section .rodata
    constructor_name db "position_new", 0

section .text
    extern malloc
    extern free
    extern malloc_failed

position_new:
    push rbp
    mov rbp, rsp
    sub rsp, 44

    ; Expect X-Position in CX
    ; Expect Y-Position in DX
    mov word [rbp - 2], cx
    mov word [rbp - 4], dx

    mov rcx, position_size
    call malloc
    test rax, rax
    jz .failed

    xor rcx, rcx
    xor rdx, rdx

    mov cx, word [rbp - 2]
    mov word [rax + position.x], cx
    mov dx, word [rbp - 4]
    mov word [rax + position.y], dx

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

position_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to POSITION-OBJECT in RCX
    call free

    mov rsp, rbp
    pop rbp
    ret