%include "../include/organizer/interactor_struc.inc"
%include "../include/organizer/console_manager_struc.inc"

global interactor_new, interactor_destroy

section .bss
    INTERACTOR_PTR resq 1

section .text
    extern malloc
    extern free

interactor_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel INTERACTOR_PTR], 0
    je .complete

    ; Expect pointer to console_manager in RCX.
    mov [rbp - 8], rcx

    mov rcx, interactor_size
    call malloc
    mov [rel INTERACTOR_PTR], rax

    mov rcx, [rbp - 8]
    mov [rax + interactor.console_manager_ptr], rcx

.complete:
    mov rax, [rel INTERACTOR_PTR]
    mov rsp, rbp
    pop rbp
    ret

interactor_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel INTERACTOR_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

interactor_create_player:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    