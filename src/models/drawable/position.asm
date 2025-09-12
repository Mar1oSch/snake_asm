global POSITION_X_OFFSET, POSITION_Y_OFFSET
global position_new, position_destroy

section .rodata
position:
    POSITION_X_OFFSET equ 0
    POSITION_Y_OFFSET equ 2
position_end:
    POSITION_SIZE equ position_end - position

section .text
    extern malloc
    extern free

position_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X-Position in CX
    ; Expect Y-Position in DX
    mov word [rbp - 2], cx
    mov word [rbp - 4], dx

    mov rcx, POSITION_SIZE
    call malloc

    mov cx, word [rbp - 2]
    mov [rax + POSITION_X_OFFSET], cx
    mov dx, word [rbp - 4]
    mov [rax + POSITION_Y_OFFSET], dx

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