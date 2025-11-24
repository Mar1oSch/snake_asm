; Strucs:
%include "../include/strucs/game/player_struc.inc"

; The player object. I decided to let the user create a player. The player is getting saved into a file with the highscore.
; If the user comes back, he can decide, if he already played and then choose the player he wants to.
; The points of a game are stored in the game object. If the actual points are higher than the actual highscore of the player, it is getting updated.
global player_new, player_destroy, get_player_points, get_player_name_length, player_update_highscore


section .bss
    ; Memory space for the created player pointer.
    ; Since there is always just one player in the game, I decided to create a kind of a singleton.
    ; If this lcl_player_ptr is 0, the constructor will create a new player object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_player_ptr resq 1


section .text
    extern malloc, free

; Here the player object is created and memory space for it allocated. 
; It needs to know the name of the player and the actual highscore.
; So the highscore will be zero, if a new player is created. But if the player is getting loaded from the file, the highscore will also be taken from it.
player_new:
    ; * Expect pointer to player name in RCX.
    ; * Expect highscore in EDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Check if a player already exists. If yes, return the pointer to it.
        cmp qword [rel lcl_player_ptr], 0
        jne .complete

        ; Save params into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], edx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_object:
        ; Creating the player, containing space for:
        ; * - Name pointer. (8 bytes)
        ; * - Highscore. (2 bytes)
        mov rcx, player_size
        call malloc
        ; Pointer to player object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _pl_malloc_failed

        mov [rel lcl_player_ptr], rax

    .set_up_object:
        ; Take first param and save it into reserved space.
        mov rcx, [rbp + 16]
        mov [rax + player.name], rcx

        ; Take second param and save it into reserved space.
        mov ecx, [rbp + 24]
        mov [rax + player.highscore], ecx

    .complete:
        ; Use the pointer to the player object as return value of this constructor.
        mov rax, qword [rel lcl_player_ptr]

        ; Restore the old stack frame and leave the constructor.
        mov rsp, rbp
        pop rbp 
        ret


get_player_name_length:
    push rbp
    mov rbp, rsp

    xor rcx, rcx
    mov rdx, [rel lcl_player_ptr]
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
    mov rdx, [rel lcl_player_ptr]
    mov [rdx + player.highscore], ecx

    mov rsp, rbp
    pop rbp
    ret

player_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel lcl_player_ptr]
    call free
    mov qword [rel lcl_player_ptr], 0

    mov rsp, rbp
    pop rbp
    ret