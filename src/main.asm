%include "../include/position_struc.inc"
%include "../include/snake/snake_struc.inc"
%include "../include/snake/unit_struc.inc"

section .data
    hello db "Worked! Pointer: %p", 13, 10, 0
    object_string db "Lets see who we are: snake_pointer: %p, head_ptr: %p, tail_ptr: %p", 13, 10, 0
    unit_string db "Have a look at the unit: char: %c direction: %d", 13, 10, 0
    position_string db "unit position: %p, x: %d, y: %d", 13, 10, 0

section .text
    global main
    extern game_new
    extern board_draw
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, 50
    mov rdx, 50
    call game_new

    ; call board_draw

    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret