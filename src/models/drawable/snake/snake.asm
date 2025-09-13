global snake_new, snake_destroy, get_snake, snake_draw, snake_add_segment

section .rodata
snake:
    SNAKE_VTABLE_OFFSET equ 0
    SNAKE_LENGTH_OFFSET equ 8
    SNAKE_HEAD_PTR_OFFSET equ 16
    SNAKE_TAIL_PTR_OFFSET equ 24
snake_end:
    SNAKE_SIZE equ snake_end - snake
    HEAD_CHAR equ "@"
    SEGMENT_CHAR equ "o"

    constructor_name db "snake_new", 0

section .bss
    SNAKE_PTR resq 1

section .text
    extern malloc
    extern free
    extern segment_new
    extern SEGMENT_CHAR_OFFSET, SEGMENT_INTERFACE_TABLE_PTR_OFFSET, SEGMENT_NEXT_SEGMENT_PTR_OFFSET
    extern INTERFACE_VTABLE_DRAWABLE_OFFSET, DRAWABLE_VTABLE_DRAW_OFFSET
    extern malloc_failed

snake_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; cmp qword [rel SNAKE_PTR], 0
    ; jne .complete

    ; Needs X-Coordinate of position in CX
    ; Needs Y-Coordinate of position in DX
    ; Use them to create the head of the snake.
    call segment_new
    mov qword [rbp - 8], rax

    mov rcx, SNAKE_SIZE
    call malloc
    test rax, rax
    jz .failed

    mov qword [rel SNAKE_PTR], rax

    mov rcx, [rbp - 8]
    mov qword [rax + SNAKE_VTABLE_OFFSET], 0
    mov qword [rax + SNAKE_HEAD_PTR_OFFSET], rcx
    mov qword [rax + SNAKE_TAIL_PTR_OFFSET], rcx
    mov qword [rax + SNAKE_LENGTH_OFFSET], 1

.complete:
    mov rax, SNAKE_PTR
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

get_snake:
    mov rax, SNAKE_PTR
    ret

snake_draw:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov qword [rbp - 8], r15
    mov qword [rbp - 16], r14
    mov qword [rbp - 24], r13
    mov qword [rbp - 32], r12

    xor r15, r15
    mov r15, [rel SNAKE_PTR]
    mov r14, [r15 + SNAKE_HEAD_PTR_OFFSET]
    mov [r14 + SEGMENT_CHAR_OFFSET], byte HEAD_CHAR
.loop:
    mov r13, [r14 + SEGMENT_INTERFACE_TABLE_PTR_OFFSET]
    mov r12, [r13 + INTERFACE_VTABLE_DRAWABLE_OFFSET]
    call [r12 + DRAWABLE_VTABLE_DRAW_OFFSET]
    cmp r14, [r15 + SNAKE_TAIL_PTR_OFFSET]
    je .complete
    mov r14, [r14 + SEGMENT_NEXT_SEGMENT_PTR_OFFSET]
    mov [r14 + SEGMENT_CHAR_OFFSET], byte SEGMENT_CHAR
    jmp .loop

.complete:
    mov r12, [rbp - 32]
    mov r13, [rbp - 24]
    mov r14, [rbp - 16]
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

snake_add_segment:
    ; Expect X-Coordinate in CX
    ; Expect Y-Coordinate in DX
    ; Expect direction in R8
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call segment_new
    mov [rbp - 8], rax
    mov r9, [rel SNAKE_PTR]
    mov r10, [r9 + SNAKE_TAIL_PTR_OFFSET]

    mov [r10 + SEGMENT_NEXT_SEGMENT_PTR_OFFSET], rax
    mov [r10], rax
    inc qword [r9 + SNAKE_LENGTH_OFFSET]
    mov rsp, rbp
    pop rbp
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