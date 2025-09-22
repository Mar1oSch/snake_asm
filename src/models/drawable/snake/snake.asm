%include "../include/interface_table_struc.inc"
%include "../include/snake/snake_struc.inc"
%include "../include/snake/unit_struc.inc"

global snake_new, snake_destroy, get_snake, snake_add_unit, snake_update

section .rodata
    HEAD_CHAR equ "@"
    UNIT_CHAR equ "o"

    constructor_name db "snake_new", 0

section .bss
    SNAKE_PTR resq 1

section .text
    extern malloc
    extern free
    extern unit_new, unit_update
    extern malloc_failed, object_not_created
    extern DRAWABLE_VTABLE_DRAW_OFFSET

;;;;;; PUBLIC FUNCTIONS ;;;;;;
snake_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel SNAKE_PTR], 0
    jne .complete

    ; Expect X- and Y-Coordinates in ECX.
    ; Expect direction in RDX.
    ; Use them to create the head of the snake.
    call unit_new
    mov qword [rbp - 8], rax

    mov rcx, snake_size
    call malloc
    test rax, rax
    jz _snake_malloc_failed

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

snake_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel SNAKE_PTR], 0
    je _snake_object_failed

    mov rcx, [rel SNAKE_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

get_snake:
    cmp qword [rel SNAKE_PTR], 0
    je _snake_object_failed

    mov rax, qword [rel SNAKE_PTR]
    ret

snake_add_unit:
    ; Expect X- and Y-Coordinates in ECX
    ; Expect direction in RDX
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel SNAKE_PTR], 0
    je _snake_object_failed

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

snake_update:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect direction in RCX
    cmp qword [rel SNAKE_PTR], 0
    je _snake_object_failed

    mov [rbp - 8], rcx                      ; Save first direction.
    mov rcx, [rel SNAKE_PTR]
    mov r8, [rcx + snake.head_ptr]
    mov [rbp - 16], r8                       ; Save active unit ptr.
    mov r9, [rcx + snake.tail_ptr]
    mov [rbp - 24], r9                          ; Save tail ptr.

.loop:
    mov rcx, [rbp - 16]
    mov rdx, [rbp - 8]
    call unit_update
    mov rcx, [rbp - 16]
    cmp rcx, [rbp - 24]
    je .complete
.loop_handle:
    mov rcx, [rcx + unit.next_unit_ptr]
    jmp .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret




;;;;;; ERROR HANDLING ;;;;;;
_snake_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret

_snake_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret