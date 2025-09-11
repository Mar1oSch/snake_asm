global head_new, head_destroy, get_head, head_get_char

section .rodata
head:
    HEAD_INTERFACE_TABLE_OFFSET equ 0
    HEAD_POSITION_PTR_OFFSET equ 8
    HEAD_CHAR_OFFSET equ 16
    HEAD_DIRECTION_OFFSET equ 24
    HEAD_NEXT_SEGMENT_PTR_OFFSET equ 32
head_end:
    HEAD_SIZE equ head_end - head
    HEAD_CHAR equ "@"
section .bss
    HEAD_PTR resq 1

section .text
    extern malloc
    extern free
    extern position_new

head_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp HEAD_PTR, 0
    jne .complete

    ; Needs X-Coordinate of position in RCX.
    ; Needs Y-Coordinate of position in RDX.

    ; Create the initial position of the head.
    call position_new
    mov qword [rbp - 8], rax

    mov rcx, HEAD_SIZE
    call malloc
    mov qword HEAD_PTR, rax

    mov rcx, qword HEAD_PTR

    mov rax, [rbp - 8]
    mov qword [rcx + HEAD_POSITION_PTR_OFFSET], rax
    mov qword [rcx + HEAD_NEXT_SEGMENT_PTR_OFFSET], 0
    mov qword [rcx + HEAD_CHAR_OFFSET], HEAD_CHAR

.complete:
    mov rax, HEAD_PTR
    mov rsp, rbp
    pop rbp
    ret

get_head:
    mov rax, HEAD_PTR
    ret

head_get_char:
    mov rax, HEAD_CHAR
    ret

head_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, HEAD_PTR
    call free

    mov rsp, rbp
    pop rbp
    ret