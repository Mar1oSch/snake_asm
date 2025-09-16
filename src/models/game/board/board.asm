%include "../include/game/board_struc.inc"

global board_new, board_destroy, board_draw, board_setup, get_board

section .rodata
    constructor_name db "board_new", 0

section .bss
    BOARD_PTR resq 1

section .text
    extern malloc
    extern free
    extern snake_new
    extern malloc_failed, object_not_created
    extern GetStdHandle, printf

board_new:
    ; Expect width in CX
    ; Expect height in DX
    push rbp
    mov rbp, rsp
    sub rsp, 72

    cmp qword [rel BOARD_PTR], 0
    jne .complete

    add cx, 2
    add dx, 2
    mov word [rbp - 8], cx
    mov word [rbp - 16], dx

    mov ax, cx
    mul dx
    mov cx, ax
    add cx, board_size
    call malloc
    test rax, rax
    jz @malloc_failed

    mov [rel BOARD_PTR], rax

    mov cx, word [rbp - 8]
    mov [rax + board.width], cx
    mov dx, word [rbp - 16]
    mov [rax + board.height], dx

    mov cx, word [rbp - 8]
    mov dx, word [rbp - 16]
    shr cx, 1
    shr dx, 1
    call snake_new
    mov rcx, [rel BOARD_PTR]
    mov [rcx + board.snake_ptr], rax
    mov qword [rcx + board.food_ptr], 0

.complete:
    mov rax, qword [rel BOARD_PTR]
    mov rsp, rbp
    pop rbp
    ret

board_draw:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je @object_failed

    mov rsp, rbp
    pop rbp
    ret

board_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je @object_failed

    call free

    mov rsp, rbp
    pop rbp
    ret

get_board:
    cmp qword [rel BOARD_PTR], 0
    je @object_failed

    mov rax, [rel BOARD_PTR]
    ret

@object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

@malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret