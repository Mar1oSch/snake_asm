global snake_new, snake_destroy, get_snake

section .rodata
snake:
    SNAKE_VTABLE_OFFSET equ 0
    SNAKE_LENGTH_OFFSET equ 8
    SNAKE_HEAD_PTR_OFFSET equ 16
    SNAKE_TAIL_PTR_OFFSET equ 24
snake_end:
    SNAKE_SIZE equ snake_end - snake

section .bss
    SNAKE_PTR resq 1

section .text
    extern malloc
    extern free
    extern head_new

snake_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp SNAKE_PTR, 0
    jne .complete

    ; Needs X-Coordinate of position in RCX
    ; Needs Y-Coordinate of position in RDX
    ; Use them to create the head of the snake.
    call head_new
    mov qword [rbp - 8], rax

    mov rcx, SNAKE_SIZE
    call malloc

    mov SNAKE_PTR, rax
    
    mov rax, [rbp - 8]
    mov qword [rax + SNAKE_HEAD_PTR_OFFSET], rax
    mov qword [rax + SNAKE_TAIL_PTR_OFFSET], rax
    mov qword [rax + SNAKE_LENGTH_OFFSET], 1

.complete
    mov rax, SNAKE_PTR
    mov rsp, rbp
    pop rbp
    ret

get_snake:
    mov rax, SNAKE_PTR
    ret

snake_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, SNAKE_PTR
    call free

    mov rsp, rbp
    pop rbp
    ret