%include "../include/game/game_struc.inc"

global game_new, game_destroy

section .rodata
    constructor_name db "game_new", 0

section .bss
    GAME_PTR resq 1

section .text
    extern malloc
    extern free
    extern board_new, board_draw
    extern malloc_failed, object_not_created

;;;;;; PUBLIC FUNCTIONS ;;;;;;
game_new:
    ; Expect width and height for the board in ECX.
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel GAME_PTR], 0
    jne .complete

    call board_new
    mov [rbp - 8], rax

    mov rcx, game_size
    call malloc
    test rax, rax
    jz _game_malloc_failed

    mov rcx, [rbp - 8]
    mov [rax + game.board_ptr], rcx

.complete:
    mov rax, [rel GAME_PTR]
    mov rsp, rbp
    pop rbp
    ret

game_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel GAME_PTR], 0
    je _game_object_failed

    mov rcx, [rel GAME_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret


;;;;;; PRIVATE FUNCTIONS ;;;;;;
_move_snake:

;;;;;; ERROR HANDLING ;;;;;;
_game_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret

_game_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret