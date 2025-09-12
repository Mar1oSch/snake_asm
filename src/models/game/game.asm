global game_new, game_destroy

section .rodata
game:
    GAME_PLAYER_PTR_OFFSET equ 0
    GAME_BOARD_PTR_OFFSET equ 8
game_end:
    GAME_SIZE equ game_end - game

section .bss
    GAME_PTR resq 1

section .text
    extern malloc
    extern free
    extern board_new, board_draw
game_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, 40
    mov rdx, 50
    call board_new
    mov [rbp - 8], rax

    mov rcx, GAME_SIZE
    call malloc

    mov rcx, [rbp - 8]
    mov [rax + GAME_BOARD_PTR_OFFSET], rcx

    call board_draw
    
    mov rsp, rbp
    pop rbp
    ret