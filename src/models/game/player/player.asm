; Strucs:
%include "../include/strucs/game/player_struc.inc"

; The player object. I decided to let the user create a player. The player is getting saved into a file with the highscore.
; If the user comes back, he can decide, if he already played and then choose the player he wants to.
; The points of a game are stored in the game object. If the actual points are higher than the actual highscore of the player, it is getting updated.
global player_new, player_destroy, get_player_points, get_player_name_length, player_update_highscore

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "player_new", 0

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

    extern malloc_failed, object_not_created

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

; The player name could have any length between 1 and 15 signs.
; To find out, how long the name actually is, I created this function. Initially the name is 15 times 0. The zeroes are getting exchanged for the letter of the input.
; So, the first 0 is after the last letter of the input.
get_player_name_length:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If player is not created yet, print a debug message.
        cmp qword [rel lcl_player_ptr], 0
        je _pl_object_failed

        ; Set loop counter to 0.
        xor rax, rax

        ; Get the player name to loop through it.
        mov rdx, [rel lcl_player_ptr]
        mov rdx, [rdx + player.name]

    .get_length_loop:
        ; Check if the active byte is 0.
        mov r8b, [rdx + rax]
        test r8b, r8b

        ; If it is, function is completed.
        jz .complete

    .get_length_loop_handle:
        ; If it is not 0, increase RAX and iterate again.
        inc rax
        jmp .get_length_loop

    .complete:
        ; RAX contains the count. It will be returned by the function.
        ; Restore the old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; If the points of the played game are higher than the current highscore, the points will be moved into the highscore field of the current player object.
player_update_highscore:
    ; * Expect new Highscore in ECX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If player is not created yet, print a debug message.
        cmp qword [rel lcl_player_ptr], 0
        je _pl_object_failed

    .move_highscore:
        ; Move active points into highscore field.
        mov rdx, [rel lcl_player_ptr]
        mov [rdx + player.highscore], ecx

    .complete:
        ; Restore the old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Simple destructor of the player object.
player_destroy:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If player is not created yet, print a debug message.
        cmp qword [rel lcl_player_ptr], 0
        je _pl_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .destroy_object:
        ; Use the local lcl_snake_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_player_ptr]
        call free
        mov qword [rel lcl_player_ptr], 0

    .complete:
        ; Restore the old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; ERROR HANDLING ;;;;;;

_pl_malloc_failed:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .debug:
        lea rcx, [rel constructor_name]
        mov rdx, rax
        call malloc_failed

    .complete:
        ; Restore old stack frame and leave debugging function.
        mov rsp, rbp
        pop rbp
        ret

_pl_object_failed:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .debug:
        lea rcx, [rel constructor_name]
        call object_not_created

    .complete:
        ; Restore old stack frame and leave debugging function.
        mov rsp, rbp
        pop rbp
        ret