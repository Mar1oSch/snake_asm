%include "../include/organizer/interactor_struc.inc"
%include "../include/organizer/designer_struc.inc"
%include "../include/game/game_struc.inc"
%include "../include/game/board_struc.inc"
%include "../include/game/player_struc.inc"
%include "../include/food/food_struc.inc"
%include "../include/position_struc.inc"
%include "../include/snake/unit_struc.inc"
%include "../include/snake/snake_struc.inc"

global game_new, game_destroy, game_start, game_reset

section .rodata
    lvl_format db "Lvl: %02d", 0
    highscore_format db "Best: %04d", 0
    points_format db " %04d", 0
    game_over db "   GAME OVER   ", 10, 0
    GAME_OVER_LENGTH equ $ - game_over

    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "game_new", 0
    direction_error db "Direction is illegal: %d", 0

section .data
    current_direction dq 2

section .bss
    GAME_PTR resq 1

section .text
    extern malloc
    extern free
    extern Sleep
    extern printf
    extern GetAsyncKeyState

    extern player_update_highscore, get_player_name_length
    extern board_new, board_draw, board_setup, board_move_snake, board_create_new_food, board_reset, get_board_width_offset, get_board_height_offset
    extern snake_add_unit
    extern console_manager_set_cursor, console_manager_set_cursor_to_end, console_manager_write_word
    extern file_manager_update_highscore, file_manager_find_name

    extern malloc_failed, object_not_created

;;;;;; PUBLIC METHODS ;;;;;;
game_new:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    ; Expect width and height for the board in ECX.
    ; Expect lvl in EDX.
    ; Expect player pointer in R8.
    ; Expect interactor pointer in R9.
    cmp qword [rel GAME_PTR], 0
    jne .complete
    mov [rbp - 8], edx
    mov [rbp - 16], r8

    mov rdx, [r9 + interactor.designer_ptr]
    mov rdx, [rdx + designer.console_manager_ptr]
    call board_new
    mov [rbp - 24], rax


    mov rcx, game_size
    call malloc
    test rax, rax
    jz _g_malloc_failed
    mov [rel GAME_PTR], rax

    mov rcx, [rbp - 24]
    mov [rax + game.board_ptr], rcx

    mov rcx, [rbp - 16]
    mov [rax + game.player_ptr], rcx

    mov ecx, [rbp - 8]
    mov [rax + game.lvl], ecx

    mov dword [rax + game.points], 0
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

game_start:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _game_setup
    call _game_play

    mov rsp, rbp
    pop rbp
    ret

game_reset:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    call board_reset
    mov rcx, [rel GAME_PTR]
    mov [rcx + game.board_ptr], rax
    mov dword [rcx + game.points], 0
    call game_start

    mov rsp, rbp
    pop rbp
    ret




;;;;;; PRIVATE METHODS ;;;;;;
_game_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    call board_setup
    call _build_scoreboard

.complete:
    mov rsp, rbp
    pop rbp
    ret

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
    mov rdx, [rcx + unit.position_ptr]
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

_get_key_press_event:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, 25h
    call GetAsyncKeyState
    test rax, 8001h
    jnz .left

    mov rcx, 26h
    call GetAsyncKeyState
    test rax, 8001h
    jnz .up

    mov rcx, 27h
    call GetAsyncKeyState
    test rax, 8001h
    jnz .right

    mov rcx, 28h
    call GetAsyncKeyState
    test rax, 8001h
    jnz .down

    jmp .complete

.left:
    cmp qword [rel current_direction], 2
    je .complete
    mov qword [rel current_direction], 0
    jmp .complete

.up:
    cmp qword [rel current_direction], 3
    je .complete
    mov qword [rel current_direction], 1
    jmp .complete

.right:
    cmp qword [rel current_direction], 0
    je .complete
    mov qword [rel current_direction], 2
    jmp .complete

.down:
    cmp qword [rel current_direction], 1
    je .complete
    mov qword [rel current_direction], 3

.complete:
    mov rax, qword [rel current_direction]
    mov rsp, rbp
    pop rbp
    ret

_collission_check:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _check_food_collission
    cmp rax, 2
    je .complete

    call _check_wall_collission
    cmp rax, 1
    je .complete

    call _check_snake_collission

.complete:
    mov rsp, rbp
    pop rbp
    ret

_check_snake_collission:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.board_ptr]
    mov rcx, [rcx + board.snake_ptr]
    mov r8, [rcx + snake.head_ptr]
    mov rdx, [r8 + unit.position_ptr]

    movzx r9, word [rdx + position.y]           ; Save Y-Position of Head
    mov word [rbp - 8], r9w
    movzx r9, word [rdx + position.x]           ; Save X-Position of Head
    mov word [rbp - 16], r9w
    mov r9, [rcx + snake.tail_ptr]              
    mov [rbp - 24], r9                          ; Save tail of Snake

    mov r8, [r8 + unit.next_unit_ptr]
.loop:
    mov r9, [r8 + unit.position_ptr]
    mov r10w, word [r9 + position.x]
    cmp r10w, word [rbp - 16]
    jne .loop_handle
    mov r10w, word [r9 + position.y]
    cmp r10w, word [rbp - 8]
    je .game_over
.loop_handle:
    cmp r8, [rbp - 24]
    je .game_on
    mov r8, [r8 + unit.next_unit_ptr]
    jmp .loop

.game_over:
    mov rax, 1
    jmp .complete

.game_on:
    mov rax, 0

.complete:
    mov rsp, rbp
    pop rbp
    ret

_check_wall_collission:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.board_ptr]
    mov rdx, [rcx + board.snake_ptr]
    mov rdx, [rdx + snake.head_ptr]
    mov rdx, [rdx + unit.position_ptr]

    cmp word [rdx + position.x], 0
    je .game_over
    movzx r9, word [rcx + board.width]
    cmp word [rdx + position.x], r9w
    je .game_over

    cmp word [rdx + position.y], 0
    je .game_over
    movzx r9, word [rcx + board.height]
    cmp word [rdx + position.y], r9w
    je .game_over

    mov rax, 0
    jmp .complete

.game_over:
    mov rax, 1

.complete:
    mov rsp, rbp
    pop rbp
    ret

_check_food_collission:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.board_ptr]

    mov rdx, [rcx + board.snake_ptr]
    mov rdx, [rdx + snake.head_ptr]
    mov rdx, [rdx + unit.position_ptr]

    mov r8, [rcx + board.food_ptr]
    mov r8, [r8 + food.position_ptr]

    movzx r9, word [rdx + position.x]
    movzx r10, word [r8 + position.x]
    cmp r9, r10
    jne .no_food_collission

    movzx r9, word [rdx + position.y]
    movzx r10, word [r8 + position.y]
    cmp r9, r10
    je .food_collission

.no_food_collission:
    mov rax, 0
    jmp .complete

.food_collission:
    mov rax, 2

.complete:
    mov rsp, rbp
    pop rbp
    ret

_add_points:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    cmp qword [rel GAME_PTR], 0
    je _g_object_failed

    mov rcx, [rel GAME_PTR]
    mov r8d, [rcx + game.lvl]

    add [rcx + game.points], r8d

    call _print_points

    mov rsp, rbp
    pop rbp
    ret

_build_scoreboard:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    cmp qword [rel GAME_PTR], 0
    je _g_object_failed

    call _print_points
    call _print_highscore
    call _print_level
    call _print_player

    mov rsp, rbp
    pop rbp
    ret

_print_player:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    call get_board_width_offset
    mov [rbp - 8], ax

    call get_board_height_offset
    mov [rbp - 16], ax

    call get_player_name_length
    mov r8, rax

    mov r9, [rel GAME_PTR]
    mov r10, [r9 + game.board_ptr]
    xor rcx, rcx
    movzx rcx, word [rbp - 8]
    shl rcx, 16
    mov cx, [r10 + board.height]
    add cx, [rbp - 16]
    inc cx
    mov rdx, [r9 + game.player_ptr]
    mov rdx, [rdx + player.name]
    xor r9, r9
    call console_manager_write_word

    mov rsp, rbp
    pop rbp
    ret

_print_level:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    call get_board_width_offset
    mov [rbp - 8], ax

    call get_board_height_offset
    mov [rbp - 16], ax

    mov r8, [rel GAME_PTR]
    mov r9, [r8 + game.board_ptr]
    xor rcx, rcx
    movzx rcx, word [rbp - 8]
    shl rcx, 16
    mov cx, [rbp - 16]
    dec cx
    call console_manager_set_cursor

    lea rcx, [rel lvl_format]
    mov rdx, [rel GAME_PTR]
    mov edx, [rdx + game.lvl]
    call printf

    mov rsp, rbp
    pop rbp
    ret

_print_points:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    call get_board_width_offset
    mov [rbp - 8], ax

    call get_board_height_offset
    mov [rbp - 16], ax

    mov r8, [rel GAME_PTR]
    mov r8, [r8 + game.board_ptr]
    movzx rcx, word [r8 + board.width]
    add cx, [rbp - 8]
    sub cx, 4
    shl rcx, 16
    mov cx, [r8 + board.height]
    add cx, [rbp - 16]
    inc cx
    call console_manager_set_cursor

    lea rcx, [rel points_format]
    mov rdx, [rel GAME_PTR]
    mov edx, [rdx + game.points]
    call printf

    mov rsp, rbp
    pop rbp
    ret

_print_highscore:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    call get_board_width_offset
    mov [rbp - 8], ax

    call get_board_height_offset
    mov [rbp - 16], ax

    mov r8, [rel GAME_PTR]
    mov r8, [r8 + game.board_ptr]
    movzx rcx, word [r8 + board.width]
    add cx, [rbp - 8]
    sub cx, 9
    shl rcx, 16
    mov cx, [rbp - 16]
    dec cx
    call console_manager_set_cursor

    lea rcx, [rel highscore_format]
    mov rdx, [rel GAME_PTR]
    mov rdx, [rdx + game.player_ptr]
    mov edx, [rdx + player.highscore]
    call printf

    mov rsp, rbp
    pop rbp
    ret

_get_delay:
    push rbp
    mov rbp, rsp

    mov rax, [rel GAME_PTR]
    mov eax, [rax + game.lvl]

    cmp rax, 9
    ja  .invalid

    lea rdx, [rel .delay_table]

    dec rax
    mov rax, [rdx + rax*8]
    jmp rax

.invalid:
    mov ax, 400
    jmp .complete

.delay_table:
    dq .first_level
    dq .second_level
    dq .third_level
    dq .fourth_level
    dq .fifth_level
    dq .sixth_level
    dq .seventh_level
    dq .eighth_level
    dq .nineth_level

.first_level:  mov ax, 400  ; etc.
               jmp .complete
.second_level: mov ax, 330
               jmp .complete
.third_level:  mov ax, 270
               jmp .complete
.fourth_level: mov ax, 220
               jmp .complete
.fifth_level:  mov ax, 180
               jmp .complete
.sixth_level:  mov ax, 140
               jmp .complete
.seventh_level:mov ax, 100
               jmp .complete
.eighth_level: mov ax, 60
               jmp .complete
.nineth_level: mov ax, 30

.complete:
    mov rsp, rbp
    pop rbp
    ret

_game_play:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    mov qword [rel current_direction], 2
    call _get_delay

    mov [rbp - 8], ax
.loop:
    call _get_key_press_event
    mov rcx, [rel current_direction]
    call _update_snake
    call board_move_snake
    call _collission_check
    cmp rax, 2
    je .food_event
    cmp rax, 1
    je .complete
.loop_handle:
    movzx rcx, word [rbp - 8]
    call Sleep
    jmp .loop

.food_event:
    call _add_points
    call snake_add_unit
    call board_create_new_food
    jmp .loop_handle

.complete:
    call _game_over
    mov rsp, rbp
    pop rbp
    ret

_game_over:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call get_board_width_offset
    mov [rbp - 8], ax

    call get_board_height_offset
    mov [rbp - 16], ax

    mov rcx, [rel GAME_PTR]
    mov r8, [rcx + game.board_ptr]
    movzx rcx, word [r8 + board.width]
    shr rcx, 1
    sub cx, GAME_OVER_LENGTH / 2
    add cx, [rbp - 8]
    inc cx
    shl rcx, 16
    mov cx, word [r8 + board.height]
    shr cx, 1
    add cx, [rbp - 16]
    lea rdx, [rel game_over]
    mov r8, GAME_OVER_LENGTH
    xor r9, r9
    call console_manager_write_word

    call console_manager_set_cursor_to_end
    call _update_highscore

    mov rcx, 2000
    call Sleep

    mov rsp, rbp
    pop rbp
    ret

_update_highscore:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rdx, [rel GAME_PTR]
    mov ecx, [rdx + game.points]
    mov r8, [rdx + game.player_ptr]
    mov r8d, [r8 + player.highscore]
    cmp ecx, r8d
    jbe .complete

    call player_update_highscore

    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.player_ptr]
    mov rcx, [rcx + player.name]
    call file_manager_find_name

    mov rdx, rax
    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.player_ptr]
    mov ecx, dword [rcx + player.highscore]
    call file_manager_update_highscore

.complete:
    mov rsp, rbp
    pop rbp
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