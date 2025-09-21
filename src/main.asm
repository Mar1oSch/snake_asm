%include "../include/position_struc.inc"
%include "../include/interface_table_struc.inc"
%include "../include/game/board_struc.inc"
%include "../include/snake/snake_struc.inc"
%include "../include/snake/unit_struc.inc"

section .data

section .text
    global main
    extern board_new
    extern board_setup
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, 20
    mov rdx, 20
    call board_new

    call board_setup

    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret
