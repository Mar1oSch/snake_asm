%include "../include/strucs/position_struc.inc"

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

    ; Expect X- and Y-Position in ECX
    mov word [rbp - 8], cx             ; Save Y-Position onto stack. (ECX = x, y)
    shr rcx, 16                        ; Shift RCX right by 16 bits. (ECX = 0, x) 
    mov word [rbp - 16], cx             ; Save X-Position onto stack. (ECX = 0, x)

    mov rcx, position_size
    call malloc
    test rax, rax
    jz .failed

    xor rcx, rcx
    xor rdx, rdx

    mov cx, word [rbp - 16]
    mov word [rax + position.x], cx
    mov dx, word [rbp - 8]
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