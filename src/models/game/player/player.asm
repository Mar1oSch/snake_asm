global player_new, player_destroy, player_get_points

section .rodata
player:
    PLAYER_NAME_PTR_OFFSET equ 0
    PLAYER_POINTS_OFFSET equ 8
end_player:
    PLAYER_SIZE equ end_player - player

section .bss
    PLAYER_PTR resq 1 

section .text
player_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel PLAYER_PTR], 0
    jne .complete

    mov rcx, PLAYER_SIZE
    call malloc

    mov qword [rel PLAYER_PTR], rax

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
    mov rax, [rax + PLAYER_POINTS_OFFSET]
    ret

player_add_points:
    ; Expect points to add in RCX
    mov rax, [rel PLAYER_PTR]
    mov rax, [rax + PLAYER_POINTS_OFFSET]
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