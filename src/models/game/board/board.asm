global board_new, board_destroy, board_draw

section .rodata
board:
    BOARD_WIDTH_OFFSET equ 0
    BOARD_HEIGHT_OFFSET equ 2
    BOARD_SNAKE_PTR_OFFSET equ 4
    BOARD_FOOD_PTR_OFFSET equ 12
board_end:

section .bss
    BOARD_PTR resq 1

section .text
    extern malloc
    extern free
    extern snake_new, snake_draw
    extern GetStdHandle, SetConsoleScreenBufferSize, SetConsoleWindowInfo

board_new:
    ; Expect width in CX
    ; Expect height in DX
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    jne .complete

    add rcx, 2
    add rdx, 2
    mov word [rbp - 8], cx
    mov word [rbp - 16], dx

    mov rax, rcx
    mul rdx
    mov rcx, rax
    call malloc
    mov [rel BOARD_PTR], rax

    mov cx, word [rbp - 8]
    mov [rax + BOARD_WIDTH_OFFSET], cx
    mov dx, word [rbp - 16]
    mov [rax + BOARD_HEIGHT_OFFSET], dx


    mov cx, word [rbp - 8]
    mov dx, word [rbp - 16]
    shr cx, 1
    shr dx, 1
    call snake_new
    mov rcx, [rel BOARD_PTR]
    mov [rcx + BOARD_SNAKE_PTR_OFFSET], rax

    mov rcx, -11
    call GetStdHandle
    mov [rbp - 24], rax

    mov rax, [rel BOARD_PTR]
    mov rcx, rax
    mov rdx, [rax + BOARD_WIDTH_OFFSET]
    call SetConsoleScreenBufferSize

.complete:
    mov rax, qword [rel BOARD_PTR]
    mov rsp, rbp
    pop rbp
    ret

board_draw:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rax, [rel BOARD_PTR]
    mov rcx, [rax + BOARD_SNAKE_PTR_OFFSET]
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
;     ; Expect pointer to segment object in RCX.
;     push rbp
;     mov rbp, rsp
;     sub rsp, 56

;     mov qword [rbp - 8], rcx
;     mov rcx, -11
;     call GetStdHandle
;     mov qword [rbp - 16], rax

;     mov rcx, rax
;     mov rax, [rbp - 8]
;     mov rdx, [rax + SEGMENT_POSITION_PTR_OFFSET]
;     call SetConsoleCursorPosition

;     mov rcx, [rbp - 16]
;     lea rdx, [rel SEGMENT_CHAR]
;     mov r8, 1
;     xor r9, r9
;     mov [rsp + 40], 0
;     call WriteConsoleA

;     mov rsp, rbp
;     pop rbp
;     ret