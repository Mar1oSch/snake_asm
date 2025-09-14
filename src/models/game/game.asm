global game_new, game_destroy

section .rodata
game_struct:
    GAME_PLAYER_PTR_OFFSET equ 0
    GAME_BOARD_PTR_OFFSET equ 8
game_end_struct:
    GAME_SIZE equ game_end_struct - game_struct

    constructor_name db "game_new", 0

section .bss
    GAME_PTR resq 1

section .text
    extern malloc
    extern free
    extern board_new, board_draw
    extern malloc_failed

game_new:
    ; Expect width in CX
    ; Expect height in DX
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call board_new
    mov [rbp - 8], rax

    mov rcx, GAME_SIZE
    call malloc
    test rax, rax
    jz .failed

    mov rcx, [rbp - 8]
    mov [rax + GAME_BOARD_PTR_OFFSET], rcx

    ; call board_draw
    
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