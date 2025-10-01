%include "../include/game/player_struc.inc"

section .rodata
    player_ptr db "%p", 13, 10, 0

section .text
    global main
    extern interactor_new, interactor_get_player, interactor_create_game, interactor_setup
    extern game_setup, game_start
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call interactor_new
    call interactor_setup
    call interactor_get_player
    test rax, rax
    jz .complete

    mov rcx, rax
    call interactor_create_game

    call game_setup
    call game_start

.complete:
    mov rsp, rbp
    pop rbp
    ret