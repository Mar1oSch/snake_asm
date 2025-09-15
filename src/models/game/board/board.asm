%include "../include/game/board_struc.inc"

global board_new, board_destroy, board_draw

section .rodata
    constructor_name db "board_new", 0

section .bss
    BOARD_PTR resq 1

section .data
    small_rect dw 0, 0, 0, 0

section .text
    extern malloc
    extern free
    extern snake_new, snake_draw
    extern GetStdHandle, SetConsoleScreenBufferSize, SetConsoleWindowInfo
    extern malloc_failed
    extern getchar

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
    jz .failed

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

    mov rcx, -11
    call GetStdHandle
    mov rcx, [rel BOARD_PTR]
    mov [rcx + board.console_handle], rax

    mov rcx, [rel BOARD_PTR + board.console_handle] ; HANDLE in rcx
    movzx rdx, word [rel BOARD_PTR + board.width]           ; width in cx
    movzx r8, word [rel BOARD_PTR + board.height]          ; height in dx
    call SetConsoleScreenBufferSize

    mov rcx, [rel BOARD_PTR + board.console_handle]
    mov rdx, 1
    lea r8, [rel small_rect]
    movzx rax, word [rel BOARD_PTR + board.width]
    mov [r8 + 4], ax
    movzx rax, word [rel BOARD_PTR + board.height]
    mov [r8 + 6], ax
    call SetConsoleWindowInfo

.complete:
    mov rax, qword [rel BOARD_PTR]
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

board_draw:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rax, [rel BOARD_PTR]
    mov rcx, [rax + board.snake_ptr]
    mov rdx, rax
    call snake_draw

    mov rsp, rbp
    pop rbp
    ret

board_destroy:
    ; Expect pointer to board object in RCX.
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret

; .board_draw_wall:
;     ; Expect pointer to unit object in RCX.
;     push rbp
;     mov rbp, rsp
;     sub rsp, 56

;     mov qword [rbp - 8], rcx
;     mov rcx, -11
;     call GetStdHandle
;     mov qword [rbp - 16], rax

;     mov rcx, rax
;     mov rax, [rbp - 8]
;     mov rdx, [rax + unit_POSITION_PTR_OFFSET]
;     call SetConsoleCursorPosition

;     mov rcx, [rbp - 16]
;     lea rdx, [rel unit_CHAR]
;     mov r8, 1
;     xor r9, r9
;     mov [rsp + 40], 0
;     call WriteConsoleA

;     mov rsp, rbp
;     pop rbp
;     ret