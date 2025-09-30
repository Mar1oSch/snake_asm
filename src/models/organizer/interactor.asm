%include "../include/organizer/interactor_struc.inc"
%include "../include/organizer/console_manager_struc.inc"

global interactor_new, interactor_setup, interactor_destroy

section .bss
    INTERACTOR_PTR resq 1

section .text
    extern malloc
    extern free
    extern printf
    extern Sleep

    extern designer_new, designer_start_screen, designer_clear

interactor_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel INTERACTOR_PTR], 0
    jne .complete

    mov rcx, interactor_size
    call malloc
    mov [rel INTERACTOR_PTR], rax

    call designer_new
    mov rcx, [rel INTERACTOR_PTR]
    mov [rcx + interactor.designer_ptr], rax

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

interactor_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call designer_start_screen
    mov rcx, 1000
    call Sleep
    call designer_clear

    mov rsp, rbp
    pop rbp
    ret