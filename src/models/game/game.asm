; Data:
%include "../include/data/game_strings/game_strings.inc"

; Strucs:
%include "../include/strucs/organizer/interactor_struc.inc"
%include "../include/strucs/organizer/designer_struc.inc"
%include "../include/strucs/game/game_struc.inc"
%include "../include/strucs/game/board_struc.inc"
%include "../include/strucs/game/player_struc.inc"
%include "../include/strucs/game/options_struc.inc"
%include "../include/strucs/food/food_struc.inc"
%include "../include/strucs/position_struc.inc"
%include "../include/strucs/snake/unit_struc.inc"
%include "../include/strucs/snake/snake_struc.inc"

global game_new, game_destroy, game_start, game_reset

section .rodata
    lvl_format db "Lvl:", 0
    lvl_length equ $ - lvl_format

    best_format db "Best:", 0
    best_length equ $ - best_format  

    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "game_new", 0
    direction_error db "Direction is illegal: %d", 0

section .data
    current_direction dq 2
    is_paused db 0

section .bss
    GAME_PTR resq 1

section .text
    extern malloc
    extern free
    extern Sleep
    extern GetAsyncKeyState
    extern printf

    extern player_update_highscore, get_player_name_length
    extern board_new, board_draw, board_setup, board_move_snake, board_create_new_food, board_reset, get_board_width_offset, get_board_height_offset, board_draw_food
    extern snake_add_unit
    extern console_manager_set_cursor, console_manager_set_cursor_to_end, console_manager_write_word, console_manager_write_number
    extern file_manager_update_highscore, file_manager_find_name
    extern designer_type_sequence
    extern helper_change_position, helper_parse_int_to_string

    extern malloc_failed, object_not_created

;;;;;; PUBLIC METHODS ;;;;;;
game_new:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    ; Expect width and height for the board in ECX.
    ; Expect options_ptr in RDX.
    ; Expect interactor pointer in R8.
    cmp qword [rel GAME_PTR], 0
    jne .complete
    mov [rbp - 8], rdx

    mov rdx, [r8 + interactor.designer_ptr]
    mov rdx, [rdx + designer.console_manager_ptr]
    call board_new
    mov [rbp - 16], rax

    mov rcx, game_size
    call malloc
    test rax, rax
    jz _g_malloc_failed
    mov [rel GAME_PTR], rax

    mov rcx, [rbp - 16]
    mov [rax + game.board_ptr], rcx

    mov rcx, [rbp - 8]
    mov [rax + game.options_ptr], rcx

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

    ; Expect options_ptr in RCX.
    mov [rbp - 8], rcx

    call board_reset
    mov rcx, [rel GAME_PTR]
    mov [rcx + game.board_ptr], rax
    mov rax, [rbp - 8]
    mov [rcx + game.options_ptr], rax
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

    ; Expect direction in CL
    cmp qword [rel GAME_PTR], 0
    je _g_object_failed

    mov [rbp - 8], cl                      ; Save first direction.
    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.board_ptr]
    mov rcx, [rcx + board.snake_ptr]
    mov r8, [rcx + snake.head_ptr]
    mov [rbp - 16], r8                       ; Save active unit ptr.
    mov r9, [rcx + snake.tail_ptr]
    mov [rbp - 24], r9                       ; Save tail ptr.

.loop:
    mov rcx, [rbp - 16]
    movzx rdx, byte [rbp - 8]
    movzx r8, byte [rcx + unit.direction]
    mov [rbp - 32], r8
    call _update_unit
    mov rcx, [rbp - 16]
    cmp rcx, [rbp - 24]
    je .complete
.loop_handle:
    mov rcx, [rcx + unit.next_unit_ptr]
    mov [rbp - 16], rcx
    mov r8, [rbp - 32]
    mov byte [rbp - 8], r8b
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
    ; Expect direction in DL.
    mov [rbp - 8], rcx
    mov [rbp - 16], dl

    call _update_unit_position

    mov rcx, [rbp - 8]
    mov dl, [rbp - 16]
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
    movzx r8, byte [rcx + unit.direction]

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
    ; Expect new direction in DL.
    mov [rcx + unit.direction], dl
    ret

_get_direction_change:
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

_get_pause_request:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, 50h
    call GetAsyncKeyState
    test rax, 1

    jz .complete

    cmp byte [rel is_paused], 1
    je .pause_stop

    mov byte [rel is_paused], 1
    jmp .complete

.pause_stop:
    mov byte [rel is_paused], 0

.complete:
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
    sub rsp, 40

    cmp qword [rel GAME_PTR], 0
    je _g_object_failed

    mov rcx, [rel GAME_PTR]
    mov r8, [rcx + game.options_ptr]
    mov r8d, [r8 + options.lvl]

    add [rcx + game.points], r8d

    call _print_points

    mov rsp, rbp
    pop rbp
    ret

_build_scoreboard:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel GAME_PTR], 0
    je _g_object_failed

    call _print_points
    call _print_level
    call _print_player
    call _print_highscore

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
    mov rdx, [r9 + game.options_ptr]
    mov rdx, [rdx + options.player_ptr]
    mov rdx, [rdx + player.name]
    xor r9, r9 
    call console_manager_write_word

    mov rsp, rbp
    pop rbp
    ret

_print_level:
    push rbp
    mov rbp, rsp
    sub rsp, 72

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
    mov [rbp - 24], ecx
    lea rdx, [rel lvl_format]
    mov r8, lvl_length
    xor r9, r9
    call console_manager_write_word

    mov ecx, [rbp - 24]
    mov rdx, lvl_length
    xor r8, r8
    call helper_change_position

    mov ecx, eax
    mov rdx, [rel GAME_PTR]
    mov rdx, [rdx + game.options_ptr]
    mov edx, [rdx + options.lvl]
    mov r8, 2
    call console_manager_write_number

    mov rsp, rbp
    pop rbp
    ret

_print_points:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    call get_board_width_offset
    mov [rbp - 8], ax

    call get_board_height_offset
    mov [rbp - 16], ax

    mov r9, [rel GAME_PTR]
    mov r8, [r9 + game.board_ptr]
    movzx rcx, word [r8 + board.width]
    add cx, [rbp - 8]
    sub cx, 3
    shl rcx, 16
    mov cx, [r8 + board.height]
    add cx, [rbp - 16]
    inc cx
    mov edx, [r9 + game.points]
    mov r8, 4
    call console_manager_write_number

    mov rsp, rbp
    pop rbp
    ret

_print_highscore:
    push rbp
    mov rbp, rsp
    sub rsp, 72

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
    mov [rbp - 32], ecx
    lea rdx, [rel best_format]
    mov r8, best_length
    xor r9, r9
    call console_manager_write_word


    mov ecx, [rbp - 32]
    mov rdx, best_length
    xor r8, r8
    call helper_change_position

    mov ecx, eax
    mov rdx, [rel GAME_PTR]
    mov rdx, [rdx + game.options_ptr]
    mov rdx, [rdx + options.player_ptr]
    mov edx, [rdx + player.highscore]
    mov r8, 4
    call console_manager_write_number

    mov rsp, rbp
    pop rbp
    ret

_get_delay:
    push rbp
    mov rbp, rsp

    mov rax, [rel GAME_PTR]
    mov rax, [rax + game.options_ptr]
    mov eax, [rax + options.lvl]

    cmp rax, 9
    ja .invalid

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
    call _get_pause_request
    cmp byte [rel is_paused], 0
    jne .pause
    call _get_direction_change
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

.pause:
    call _pause
    jmp .loop_handle

.complete:
    call _game_over
    mov rsp, rbp
    pop rbp
    ret

_pause:
    push rbp
    mov rbp, rsp
    sub rsp, 40

.loop:
    call _get_pause_request
    cmp byte [rel is_paused], 0
    je .complete

    lea rcx, [rel paused_table]
    mov rdx, paused_table_size
    xor r8, r8
    call designer_type_sequence
    call console_manager_set_cursor_to_end

    mov rcx, 500
    call Sleep

    call _get_pause_request
    cmp byte [rel is_paused], 0
    je .complete

    lea rcx, [rel empty_table]
    mov rdx, empty_table_size
    xor r8, r8
    call designer_type_sequence
    call console_manager_set_cursor_to_end

    mov rcx, 500
    call Sleep

    call _get_pause_request
    cmp byte [rel is_paused], 0
    jne .loop


.complete:
    lea rcx, [rel empty_table]
    mov rdx, empty_table_size
    xor r8, r8
    call designer_type_sequence

    call board_draw_food

    mov rsp, rbp
    pop rbp
    ret

_game_over:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel game_over_table]
    mov rdx, game_over_table_size
    xor r8, r8
    call designer_type_sequence

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

    call _add_bonus_points

    mov rdx, [rel GAME_PTR]
    mov ecx, [rdx + game.points]
    mov r8, [rdx + game.options_ptr]
    mov r8, [r8 + options.player_ptr]
    mov r8d, [r8 + player.highscore]
    cmp ecx, r8d
    jbe .complete

    call player_update_highscore

    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.options_ptr]
    mov rcx, [rcx + options.player_ptr]
    mov rcx, [rcx + player.name]
    call file_manager_find_name

    mov rdx, rax
    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.options_ptr]
    mov rcx, [rcx + options.player_ptr]
    mov ecx, dword [rcx + player.highscore]
    call file_manager_update_highscore

.complete:
    mov rsp, rbp
    pop rbp
    ret

_add_bonus_points:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel GAME_PTR]
    mov rcx, [rcx + game.board_ptr]
    movzx rax, word [rcx + board.width]
    dec rax
    movzx rdx, word [rcx + board.height]
    dec rdx
    mul rdx

    mov r8, [rcx + board.snake_ptr]
    mov r8, [r8 + snake.length]
    cmp r8, rax
    jb .complete

    mov dword [rcx + game.points], 100
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
    movzx rdx, byte [rdx + unit.direction]
    call printf

    mov rsp, rbp
    pop rbp
    ret