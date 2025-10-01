%include "../include/game/player_struc.inc"

section .rodata
    player_ptr db "%p", 13, 10, 0

section .text
    global main
    extern interactor_new, interactor_create_game, interactor_setup, interactor_start_game, interactor_after_game_dialogue
    extern game_setup, game_start
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call interactor_new
    call interactor_setup

    mov rcx, rax
    call interactor_create_game

.loop:
    call interactor_start_game
    call interactor_after_game_dialogue
    test rax, rax
    jne .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret