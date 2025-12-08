; The main function.
; It simply tells the interactor what to do.

section .text
    global main

    extern interactor_new, interactor_create_game, interactor_setup, interactor_start_game, interactor_replay_game

main:
.set_up:
    ; Set up stack frame without local variables.
    push rbp
    mov rbp, rsp

    ; Reserve 32 bytes shadow space for called functions.
    sub rsp, 32

.create_interactor:
    call interactor_new

.set_up_interactor:
    call interactor_setup

.create_game:
    mov rcx, rax
    call interactor_create_game

.start_game:
    call interactor_start_game

.replay_game:
    call interactor_replay_game

.complete:
    ; Restore old stack frame and return to system.
    mov rsp, rbp
    pop rbp
    ret