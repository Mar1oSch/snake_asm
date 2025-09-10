global snake_new, snake_destroy

section .rodata
snake:
    SNAKE_VTABLE_OFFSET equ 0
    SNAKE_POSITION_PTR_OFFSET equ 8
    ; DIRECTION: 0 = left, 1 = up, 2 = right, 3 = down
    SNAKE_DIRECTION_OFFSET equ 24
    SNAKE_LENGTH_OFFSET equ 16
    SNAKE_HEAD_OFFSET equ 32
snake_end:
    SNAKE_SIZE equ snake_end - snake

section .text
    extern malloc
    extern free
    extern position_new

snake_new:
    ; Needs X-Coordinate of position in RCX
    ; Needs Y-Coordinate of position in RDX

    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov qword [rbp - 8], rcx
    mov qword [rbp - 16], rdx

    mov rcx, SNAKE_SIZE
    call malloc

    mov qword [rbp - 24], rax

    mov rcx, qword [rbp - 8]
    mov rdx, qword [rbp - 16]
    call position_new

    mov qword [rax + SNAKE_POSITION_PTR_OFFSET], rax
    mov qword [rax + SNAKE_DIRECTION_OFFSET], 2
    mov qword [rax + SNAKE_LENGTH_OFFSET], 1

