%include "../include/game/player_struc.inc"

global player_new, player_destroy, get_player_points, get_player_name_length, get_player, player_update_highscore

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
    ; Expect highscroe in EDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], edx

    mov rcx, player_size
    call malloc
    mov [rel PLAYER_PTR], rax

    mov rcx, [rbp - 8]
    mov [rax + player.name], rcx
    mov ecx, [rbp - 16]
    mov [rax + player.highscore], ecx

.complete:
    mov rax, [rel PLAYER_PTR]
    mov rsp, rbp
    pop rbp 
    ret

get_player:
    mov rax, [rel PLAYER_PTR]
    ret

get_player_name_length:
    push rbp
    mov rbp, rsp

    xor rcx, rcx
    mov rdx, [rel PLAYER_PTR]
    mov rdx, [rdx + player.name]
.loop:
    mov r8b, [rdx + rcx]
    test r8b, r8b
    jz .complete
    inc rcx
    jmp .loop

.complete:
    mov rax, rcx
    mov rsp, rbp
    pop rbp
    ret

player_update_highscore:
    push rbp
    mov rbp, rsp

    ; Expect new Highscore in ECX.
    mov rdx, [rel PLAYER_PTR]
    mov [rdx + player.highscore], ecx

    mov rsp, rbp
    pop rbp
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