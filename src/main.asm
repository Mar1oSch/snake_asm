section .text
    global main
    extern interactor_new, interactor_create_game, interactor_setup, interactor_start_game, interactor_replay_game

main:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    call interactor_new
    call interactor_setup

    mov rcx, rax
    call interactor_create_game
    call interactor_start_game

    call interactor_replay_game

.complete:
    mov rsp, rbp
    pop rbp
    ret