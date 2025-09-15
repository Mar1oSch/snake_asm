%include "../include/interface_table_struc.inc"
%include "../include/snake/snake_struc.inc"
%include "../include/snake/unit_struc.inc"

global snake_new, snake_destroy, get_snake, snake_draw, snake_add_unit

section .rodata
    HEAD_CHAR equ "@"
    UNIT_CHAR equ "o"

    constructor_name db "snake_new", 0

section .bss
    SNAKE_PTR resq 1

section .text
    extern malloc
    extern free
    extern unit_new
    extern malloc_failed
    extern DRAWABLE_VTABLE_DRAW_OFFSET
snake_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel SNAKE_PTR], 0
    jne .complete

    ; Needs X-Coordinate of position in CX
    ; Needs Y-Coordinate of position in DX
    ; Use them to create the head of the snake.
    call unit_new
    mov qword [rbp - 8], rax

    mov rcx, snake_size
    call malloc
    test rax, rax
    jz .failed

    mov qword [rel SNAKE_PTR], rax

    mov rcx, [rbp - 8]
    mov qword [rax + snake.head_ptr], rcx
    mov qword [rax + snake.tail_ptr], rcx
    mov qword [rax + snake.length], 1

.complete:
    mov rax, qword [rel SNAKE_PTR]
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
    mov rax, qword [rel SNAKE_PTR]
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
    mov r14, [r15 + snake.head_ptr]
    mov [r14 + unit.char], byte HEAD_CHAR
.loop:
    mov r13, [r14 + unit.interface_table_ptr]
    mov r12, [r13 + interface_table.vtable_drawable_ptr]
    call [r12 + DRAWABLE_VTABLE_DRAW_OFFSET]
    cmp r14, [r15 + snake.tail_ptr]
    je .complete
    mov r14, [r14 + unit.next_unit_ptr]
    mov [r14 + unit.char], byte UNIT_CHAR
    jmp .loop

.complete:
    mov r12, [rbp - 32]
    mov r13, [rbp - 24]
    mov r14, [rbp - 16]
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

snake_add_unit:
    ; Expect X-Coordinate in CX
    ; Expect Y-Coordinate in DX
    ; Expect direction in R8
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call unit_new
    mov [rbp - 8], rax
    mov r9, [rel SNAKE_PTR]
    mov r10, [r9 + snake.tail_ptr]

    mov [r10 + unit.next_unit_ptr], rax
    mov [r10], rax
    inc qword [r9 + snake.length]
    mov rsp, rbp
    pop rbp
    ret

snake_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel SNAKE_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret