%include "../include/game/game_struc.inc"
%include "../include/game/board_struc.inc"
%include "../include/position_struc.inc"
%include "../include/snake/unit_struc.inc"
%include "../include/snake/snake_struc.inc"

global game_new, game_destroy, game_setup

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "game_new", 0
    direction_error db "Direction is illegal: %d"
section .bss
    GAME_PTR resq 1

section .text
    extern malloc
    extern free
    extern Sleep
    extern printf

    extern player_new
    extern board_new, board_draw, board_setup, board_move_snake
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
    jz _g_malloc_failed
    mov [rel GAME_PTR], rax

    mov rcx, [rbp - 8]
    mov [rax + game.board_ptr], rcx

    call player_new
    mov rcx, [rel GAME_PTR]
    mov [rcx + game.player_ptr], rax

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
    je _g_object_failed

    mov rcx, [rel GAME_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

game_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call board_setup

    ; Save non volatile regs.
    mov [rbp - 8], r15          

    mov r15, 10
.loop:
    mov rcx, 2
    call _update_snake
    call board_move_snake
    mov rcx, 500
    call Sleep
    cmp r15, 0
    je .next_loop
    dec r15
    jmp .loop

.next_loop:
    mov r15, 10
    .loop_go:
        mov rcx, 1
        call _update_snake
        call board_move_snake
        mov rcx, 500
        call Sleep
        cmp r15, 0
        je .complete
        dec r15
        jmp .loop_go

.complete:
    ; Restore non volatile regs.
    mov r15, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret






;;;;;; PRIVATE FUNCTIONS ;;;;;;
_update_snake:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect direction in RCX
    cmp qword [rel GAME_PTR], 0
    je _g_object_failed

    mov [rbp - 8], rcx                      ; Save first direction.
    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.board_ptr]
    mov rcx, [rcx + board.snake_ptr]
    mov r8, [rcx + snake.head_ptr]
    mov [rbp - 16], r8                       ; Save active unit ptr.
    mov r9, [rcx + snake.tail_ptr]
    mov [rbp - 24], r9                       ; Save tail ptr.

.loop:
    mov rcx, [rbp - 16]
    mov rdx, [rbp - 8]
    mov r8, [rcx + unit.direction]
    mov [rbp - 32], r8
    call _update_unit
    mov rcx, [rbp - 16]
    cmp rcx, [rbp - 24]
    je .complete
.loop_handle:
    mov rcx, [rcx + unit.next_unit_ptr]
    mov [rbp - 16], rcx
    mov r8, [rbp - 32]
    mov [rbp - 8], r8
    jmp .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret

_update_unit:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to unit object in RCX.
    ; Expect direction in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx

    call _update_unit_position

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call _update_unit_direction

    mov rsp, rbp
    pop rbp
    ret

_update_unit_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to unit in RCX.
    mov [rbp - 8], rcx
    mov rdx, [rcx + unit.position_ptr]
    mov [rbp - 16], rdx                             ; Save position pointer of unit.

    mov r8, [rcx + unit.direction]
    cmp r8, 0
    je .left
    cmp r8, 1
    je .up
    cmp r8, 2
    je .right
    cmp r8, 3
    je .down
    call _u_direction_error

; Update the position of the unit depending on its direction.
.left:
    dec word [rdx + position.x]
    jmp .complete
.up:
    dec word [rdx + position.y]
    jmp .complete
.right:
    inc word [rdx + position.x]
    jmp .complete
.down:
    inc word [rdx + position.y]

.complete:
    mov rsp, rbp
    pop rbp
    ret

_update_unit_direction:
    ; Expect pointer to unit object in RCX.
    ; Expect new direction in RDX.
    mov [rcx + unit.direction], rdx
    ret




;;;;;; ERROR HANDLING ;;;;;;
_g_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret

_g_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

_u_direction_error:
    ; Expect pointer to unit object in RCX.
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov [rbp - 8], rcx
    lea rcx, [rel direction_error]
    mov rdx, [rbp - 8]
    mov rdx, [rdx + unit.direction]
    call printf

    mov rsp, rbp
    pop rbp
    ret