%include "../include/strucs/game/options_struc.inc"

global options_new, options_destroy

section .bss
    OPTIONS_PTR resq 1

section .text
    extern malloc, free

options_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect player pointer in RCX.
    ; Expect lvl in EDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], edx

    mov rcx, options_size
    call malloc

    mov [rel OPTIONS_PTR], rax

    mov rcx, [rbp - 8]
    mov [rax + options.player_ptr], rcx
    mov ecx, [rbp - 16]
    mov [rax + options.lvl], ecx

    mov rsp, rbp
    pop rbp
    ret

options_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel OPTIONS_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret