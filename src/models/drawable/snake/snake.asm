%include "../include/interface_table_struc.inc"
%include "../include/position_struc.inc"
%include "../include/snake/snake_struc.inc"
%include "../include/snake/unit_struc.inc"

global snake_new, snake_destroy, get_snake, snake_add_unit, snake_update, snake_get_tail_position, snake_reset

section .rodata
    HEAD_CHAR equ "@"

    constructor_name db "snake_new", 0

section .bss
    SNAKE_PTR resq 1

section .text
    extern malloc
    extern free
    extern unit_new, unit_update, unit_destroy
    extern malloc_failed, object_not_created
    extern DRAWABLE_VTABLE_DRAW_OFFSET

;;;;;; PUBLIC METHODS ;;;;;;
snake_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel SNAKE_PTR], 0
    jne .complete

    ; Expect X- and Y-Coordinates in ECX.
    ; Expect direction in RDX.
    ; Use them to create the head of the snake.
    mov r8, HEAD_CHAR
    call unit_new
    mov qword [rbp - 8], rax

    mov rcx, snake_size
    call malloc
    test rax, rax
    jz _s_malloc_failed

    mov qword [rel SNAKE_PTR], rax

    mov rcx, [rbp - 8]
    mov qword [rax + snake.head_ptr], rcx
    mov qword [rax + snake.tail_ptr], rcx
    mov qword [rax + snake.length], 1

    ; Save non volatile regs.
    mov [rbp - 16], r15

    mov r15, 7

.loop:
    call snake_add_unit
    cmp r15, 0
    je .complete
    dec r15
    jmp .loop

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
    je _s_object_failed

    mov rcx, [rel SNAKE_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

; snake_reset:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 40

;     mov [rbp - 8], r15

;     mov r15, [rel SNAKE_PTR]
;     mov rcx, [r15 + snake.tail_ptr]
;     mov [rbp - 16], rcx
;     mov r15, [r15 + snake.head_ptr]

; .loop:
;     mov rcx, r15
;     call unit_destroy
; .loop_handle:
;     cmp r15, [rbp - 16]
;     jne .complete
;     mov r15, [r15 + unit.next_unit_ptr]
;     jmp .loop

; .complete:
;     call snake_destroy
;     mov qword [rel SNAKE_PTR], 0

;     mov r15, [rbp - 8]
;     mov rsp, rbp
;     pop rbp
;     ret

get_snake:
    cmp qword [rel SNAKE_PTR], 0
    je _s_object_failed

    mov rax, qword [rel SNAKE_PTR]
    ret

snake_get_tail_position:
    cmp qword [rel SNAKE_PTR], 0
    je _s_object_failed

    mov rax, [rel SNAKE_PTR]
    mov rax, [rax + snake.tail_ptr]
    mov r8, [rax + unit.position_ptr]
    movzx rax, word [r8 + position.x]
    shl rax, 16
    mov ax, [r8 + position.y]

    ret

snake_add_unit:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    cmp qword [rel SNAKE_PTR], 0
    je _s_object_failed

    mov rcx, [rel SNAKE_PTR]
    mov rcx, [rcx + snake.tail_ptr]
    mov rdx, [rcx + unit.direction]
    mov rcx, [rcx + unit.position_ptr]
    movzx rax, word [rcx + position.x]
    mov [rbp - 8], ax
    shl rax, 16
    mov ax, [rcx + position.y]
    mov [rbp - 16], ax

    cmp rdx, 0
    je .left
    cmp rdx, 1
    je .up
    cmp rdx, 2
    je .right
    cmp rdx, 3
    je .down

.left:
    inc word [rbp - 8]
    jmp .create_unit
.up:
    inc word [rbp - 16]
    jmp .create_unit
.right:
    dec word [rbp - 8]
    jmp .create_unit
.down:
    dec word [rbp - 16]

.create_unit:
    movzx rcx, word [rbp - 8]
    shl rcx, 16
    mov cx, [rbp - 16]
    xor r8, r8
    call unit_new
    mov [rbp - 24], rax
    mov r9, [rel SNAKE_PTR]
    mov r10, [r9 + snake.tail_ptr]

    mov [r10 + unit.next_unit_ptr], rax
    mov [r9 + snake.tail_ptr], rax
    inc qword [r9 + snake.length]

.complete:
    mov rsp, rbp
    pop rbp
    ret




;;;;;; ERROR HANDLING ;;;;;;
_s_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret

_s_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret