%include "../include/organizer/interactor_struc.inc"
%include "../include/organizer/console_manager_struc.inc"

global interactor_new, interactor_destroy

section .rodata
    
section .bss
    INTERACTOR_PTR resq 1

section .text
    extern malloc
    extern free

    extern console_manager_new

interactor_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel INTERACTOR_PTR], 0
    jne .complete

    mov rcx, interactor_size
    call malloc
    mov [rel INTERACTOR_PTR], rax

    call console_manager_new
    mov rcx, [rel INTERACTOR_PTR]
    mov [rcx + interactor.console_manager_ptr], rax

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

interactor_start_screen:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    

    