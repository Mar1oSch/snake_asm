; Constants:
%include "./include/data/organizer/interactor/interactor_constants.inc"

; Strucs:
%include "./include/strucs/organizer/interactor_struc.inc"

; The main function.
; It simply tells the interactor what to do.

section .text
    global main

    extern interactor_static_vtable

main:
.set_up:
    ; Set up stack frame.
    ; * 8 bytes local variables.
    ; * 8 bytes to keep stack 16-byte aligned.
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; Save non-volatile regs.
    mov [rbp - 8], rbx

    ; Reserve 32 bytes shadow space for called functions.
    sub rsp, 32

.create_interactor:
    lea r10, [rel interactor_static_vtable]
    call [r10 + INTERACTOR_STATIC_CONSTRUCTOR_OFFSET]

    ; Save interactor.methods_table into RBX.
    mov rbx, rax
    mov rbx, [rbx + interactor.methods_vtable_ptr]

.set_up_interactor:
    call [rbx + INTERACTOR_METHODS_SETUP_OFFSET]

.create_game:
    mov rcx, rax
    call [rbx + INTERACTOR_METHODS_CREATE_GAME_OFFSET]

.start_game:
    call [rbx + INTERACTOR_METHODS_START_GAME_OFFSET]

.replay_game:
    call [rbx + INTERACTOR_METHODS_REPLAY_GAME_OFFSET]

.complete:
    ; Restore non-volatile regs.
    mov rbx, [rbp - 8]
    ; Restore old stack frame and return to system.
    mov rsp, rbp
    pop rbp
    ret