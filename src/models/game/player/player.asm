%include "../include/game/player_struc.inc"

global player_new, player_destroy, player_get_points

section .rodata
    player_name db "Mario", 13, 10, 0

section .bss
    PLAYER_PTR resq 1 

section .text
    extern malloc
    extern free

player_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel PLAYER_PTR], 0
    jne .complete

    ; Expect pointer to player_name in RCX.
    mov [rbp - 8], rcx

    mov rcx, player_size
    call malloc

    mov qword [rel PLAYER_PTR], rax
    mov rcx, [rbp - 8]
    mov [rax + player.name_ptr], rcx
    mov qword [rax + player.points], 0
.complete:
    mov rax, [rel PLAYER_PTR]
    mov rsp, rbp
    pop rbp 
    ret

get_player:
    mov rax, [rel PLAYER_PTR]
    ret

player_get_points:
    mov rax, [rel PLAYER_PTR]
    mov rax, [rax + player.points]
    ret

player_add_points:
    ; Expect points to add in RCX
    mov rax, [rel PLAYER_PTR]
    mov rax, [rax + player.points]
    add [rax], rcx
    ret

player_destroy:
    ; Expect pointer to player object in RCX
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret