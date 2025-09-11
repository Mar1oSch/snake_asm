global POSITION_X_OFFSET, POSITION_Y_OFFSET
global position_new, position_destroy

section .rodata
position:
    POSITION_X_OFFSET equ 0
    POSITION_Y_OFFSET equ 8
position_end:
    POSITION_SIZE equ position_end - position

section .text
    extern malloc
    extern free

position_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X-Position in RCX
    ; Expect Y-Position in RDX
    mov qword [rbp - 8], rcx
    mov qword [rbp - 16], rdx

    mov rcx, POSITION_SIZE
    call malloc

    mov rcx, qword [rbp - 8]
    mov [rax + POSITION_X_OFFSET], rcx
    mov rdx, qword [rbp - 16]
    mov [rax + POSITION_Y_OFFSET], rdx

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