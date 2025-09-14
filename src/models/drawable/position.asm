global POSITION_X_OFFSET, POSITION_Y_OFFSET
global position_new, position_destroy

section .rodata
position_struct:
    POSITION_X_OFFSET equ 0
    POSITION_Y_OFFSET equ 2
position_end_struct:
    POSITION_SIZE equ position_end_struct - position_struct

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

    mov rcx, POSITION_SIZE
    call malloc
    test rax, rax
    jz .failed

    mov cx, word [rbp - 2]
    mov [rax + POSITION_X_OFFSET], cx
    mov dx, word [rbp - 4]
    mov [rax + POSITION_Y_OFFSET], dx

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