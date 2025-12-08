; Data:
%include "./include/data/game/game_strings.inc"

; Constants:
%include "./include/data/snake/snake_constants.inc"
%include "./include/data/game/board/board_constants.inc"

; Strucs:
%include "./include/strucs/organizer/interactor_struc.inc"
%include "./include/strucs/organizer/designer_struc.inc"
%include "./include/strucs/game/game_struc.inc"
%include "./include/strucs/game/board_struc.inc"
%include "./include/strucs/game/player_struc.inc"
%include "./include/strucs/game/options_struc.inc"
%include "./include/strucs/food/food_struc.inc"
%include "./include/strucs/position_struc.inc"
%include "./include/strucs/snake/unit_struc.inc"
%include "./include/strucs/snake/snake_struc.inc"

; This is one of the more complicated classes:
; The game itself. It has a board, which it delegates to draw the updated game.
; It has options, how it handles the player and the level.
; And it has points. Each game ,the player reaches some points. At the end, the game compares the highscore of the current player with the points of that round. If this round the player reached more points than the acutal highscore, the points are the new highscore.

global game_new, game_destroy, game_start, game_reset

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "game_new", 0
    direction_error db "Direction is illegal: %d", 0

section .data
    ; Save the current direction of the snakes head.
    current_direction dq 2

    ; Check, if the player wants to puse the game.
    is_paused db 0

section .bss
    ; Memory space for the created game pointer.
    ; Since there is always just one game in the game, I decided to create a kind of a singleton.
    ; If this lcl_game_ptr is 0, the constructor will create a new game object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_game_ptr resq 1

section .text
    extern malloc, free
    extern Sleep
    extern GetAsyncKeyState
    extern printf

    extern board_new
    extern player_update_highscore, get_player_name_length
    extern console_manager_write_word, console_manager_write_number
    extern file_manager_update_highscore, file_manager_get_name
    extern designer_type_sequence
    extern helper_change_position

    extern malloc_failed, object_not_created

;;;;;; PUBLIC METHODS ;;;;;;

; Here the game is created. Since itself is creating the board, it needs to know the dimensions of it. 
game_new:
    ; * Expect width and height for the board in ECX.
    ; * Expect options pointer in RDX.
    ; * Expect interactor pointer in R8.
    .set_up:
        ; Set up stack frame:
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Check if a game already exists. If yes, return the pointer to it.
        cmp qword [rel lcl_game_ptr], 0
        jne .complete

        ; Save params into shadow space.
        mov [rbp + 16], rdx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .create_depended_objects:
        ; ECX already contains the board dimensions.
        ; Moving console manager pointer into RDX.
        mov rdx, [r8 + interactor.designer_ptr]
        mov rdx, [rdx + designer.console_manager_ptr]
        call board_new
        ; * First local variable: Board pointer.
        mov [rbp - 8], rax

    .create_object:
        ; Creating the game itself, containing space for:
        ; * - Options pointer. (8 bytes)
        ; * - Board pointer. (8 bytes)
        ; * - Points. (4 bytes)
        mov rcx, game_size
        call malloc
        ; Pointer to game object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _g_malloc_failed

        ; Save pointer to initially reserved space. Object is "officially" created now.
        mov [rel lcl_game_ptr], rax

    .set_up_object:
        ; Save board pointer into reserved space.
        mov rcx, [rbp - 8]
        mov [rax + game.board_ptr], rcx

        ; Save options pointer into reserved space.
        mov rcx, [rbp + 16]
        mov [rax + game.options_ptr], rcx

        ; Initialize points to zero.
        mov dword [rax + game.points], 0

    .complete:
        ; Use the pointer to the game object as return value of this constructor.
        mov rax, qword [rel lcl_game_ptr]

        ; Restore the old stack frame and leave the constructor.
        mov rsp, rbp
        pop rbp
        ret

; Simple destructor to free memory space.
game_destroy:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .destroy_object:
        ; Use the local lcl_game_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_game_ptr]
        call free
        mov qword [rel lcl_game_ptr], 0

    .complete:
        ; Restore old stack frame and leave destructor.
        mov rsp, rbp
        pop rbp
        ret

; A simple wrapper function which is calling the more complicated private functions.
game_start:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .call_functions:
        call _game_setup
        call _game_play

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Resetting the game to play a new round.
game_reset:
    ; * Expect options pointer in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Save params into shadow space.
        mov [rbp + 16], rcx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .reset_board:
        ; Reset the board and all of its depending objects.
        mov r10, [rel lcl_game_ptr]
        mov r10, [r10 + game.board_ptr]
        mov r10, [r10 + board.methods_vtable_ptr]
        call [r10 + BOARD_METHODS_VTABLE_RESET_OFFSET]
        ; Pointer to new board is returned in RAX.

    .set_up_game:
        ; Already existing game is being updated.
        ; At first the resetted board is moved into reserved space.
        mov rcx, [rel lcl_game_ptr]
        mov [rcx + game.board_ptr], rax

        ; The passed options pointer is moved into reserved space.
        mov rax, [rbp + 16]
        mov [rcx + game.options_ptr], rax

        ; The new game is initialized with 0 points.
        mov dword [rcx + game.points], 0

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; PRIVATE METHODS ;;;;;;

; Another wrapper function, which is demanding the board to setup and then builds the scoreboard.
_game_setup:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .call_functions:
        ; Setup board.
        mov r10, [rel lcl_game_ptr]
        mov r10, [r10 + game.board_ptr]
        mov r10, [r10 + board.methods_vtable_ptr]
        call [r10 + BOARD_METHODS_VTABLE_SETUP_OFFSET]

        call _build_scoreboard

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; GAME PLAY ;;;;;;

; This is the active game. It is organizing the rules and the mechanics.
_game_play:
    .set_up:
        ; Set up stack frame:
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Starting direction: Right.
        mov qword [rel current_direction], 2

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12

        ; Get the delay defined inside the options.
        mov rbx, [rel lcl_game_ptr]
        mov r12, [rbx + game.options_ptr]
        mov r12w, [r12 + options.delay]

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .game_loop:
        ; At first check if the "P" button was pressed.
        call _request_pause
        cmp byte [rel is_paused], 0
        jne .pause

        ; Then check, if a direction change was requested.
        call _request_direction_change
        mov rcx, [rel current_direction]

        ; Update the snake and use the new direction.
        call _update_snake

        ; Use the old snake tail position to move the snake and let the board erase the last unit.
        mov r10, [rbx + game.board_ptr]
        mov r10, [r10 + board.methods_vtable_ptr]
        mov ecx, eax
        call [r10 + BOARD_METHODS_VTABLE_MOVE_SNAKE_OFFSET]

        ; Check, if the snake collided with something. 
        call _collission_check
        cmp rax, 2
        je .food_event
        cmp rax, 1
        je .game_over

    .game_loop_handle:
        ; Sleep before the new iteration.
        movzx rcx, r12w
        call Sleep
        jmp .game_loop

    .food_event:
        call _add_points

        ; Add snake unit.
        mov r10, [rbx + game.board_ptr]
        mov r10, [r10 + board.snake_ptr]
        mov r10, [r10 + snake.methods_vtable_ptr]
        call [r10 + SNAKE_METHODS_VTABLE_ADD_UNIT_OFFSET]

        ; Create new food.
        mov r10, [rbx + game.board_ptr]
        mov r10, [r10 + board.methods_vtable_ptr]
        call [r10 + BOARD_METHODS_VTABLE_CREATE_FOOD_OFFSET]

        jmp .game_loop_handle

    .pause:
        call _pause
        jmp .game_loop_handle

    .game_over:
        call _game_over

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_add_points:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .add:
        mov rcx, [rel lcl_game_ptr]
        mov r8, [rcx + game.options_ptr]
        mov r8d, [r8 + options.lvl]
        add [rcx + game.points], r8d

    .print:
        call _print_points

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_pause:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    ; Let the " P A U S E " appear and disappear.
    .pause_loop:
        call _request_pause
        cmp byte [rel is_paused], 0
        je .complete

        lea rcx, [rel paused_table]
        mov rdx, paused_table_size
        xor r8, r8
        call designer_type_sequence

        mov rcx, 500
        call Sleep

        call _request_pause
        cmp byte [rel is_paused], 0
        je .complete

        lea rcx, [rel empty_table]
        mov rdx, empty_table_size
        xor r8, r8
        call designer_type_sequence

        mov rcx, 500
        call Sleep

        call _request_pause
        cmp byte [rel is_paused], 0
        jne .pause_loop

    ; User wants to play on.
    ; Empty the letters and the board draw the food again.
    .complete:
        lea rcx, [rel empty_table]
        mov rdx, empty_table_size
        xor r8, r8
        call designer_type_sequence

        mov r10, [rel lcl_game_ptr]
        mov r10, [r10 + game.board_ptr]
        mov r10, [r10 + board.methods_vtable_ptr]
        call [r10 + BOARD_METHODS_VTABLE_DRAW_FOOD_OFFSET]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; UPDATING METHODES ;;;;;;

; This is one of the main functions of the game itself.
; It is updating the snake.
; So, it needs to know the direction the head is going next. Then it is going down through the linked list and passing the direction downwards.
; That means, I have to save the old direction of the unit first, then update it depending on its new direction. It is passing the old direction down to the next unit as its new direction.
; It will return the position of the old tail, to let the board know, where it has to erase a unit.
_update_snake:
    ; * Expect direction in CL
    .set_up:
        ; Set up stack frame:
        ; * 40 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14
        mov [rbp - 40], r15


    .set_up_loop_base:
        ; I am setting up the base for the update loop:
        ; * - RBX is going to be the tail pointer. After every iteration, I will check, if the tail is reached.
        ; * - R12 is the active unit getting updated.
        ; * - R13B will hold the new direction.
        ; * - R14B will hold the old direction.
        ; * - R15D will hold the old tail position.

        ; At first I save the new head direction into R13B
        mov r13b, cl

        ; Prepare the snake pointer in RCX.
        mov rcx, [rel lcl_game_ptr]
        mov rcx, [rcx + game.board_ptr]
        mov rcx, [rcx + board.snake_ptr]

        ; Active unit to get updated.
        mov r12, [rcx + snake.head_ptr]

        ; Tail pointer as base.
        mov rbx, [rcx + snake.tail_ptr]

        ; Save the old position of the tail.
        mov rcx, [rbx + unit.position_ptr]
        mov r15w, [rcx + position.x]             
        shl r15d, 16
        mov r15w, [rcx + position.y]

    .update_loop:
        ; At first, I preserve the active direction.
        mov r14b, [r12 + unit.direction]

        ; Now I prepare the params for the unit update:
        ; * - Pointer to unit in RCX.
        ; * - New direction in RDX.
        ; And the unit gets updated.
        mov rcx, r12
        mov dl, r13b
        call _update_unit

        ; Check if I updated the tail. If yes, function is completed.
        cmp r12, rbx
        je .complete

    .update_loop_handle:
        ; Jump to the next unit.
        ; Old direction is the new direction now.
        ; Iterate again.
        mov r12, [r12 + unit.next_unit_ptr]
        mov r13b, r14b
        jmp .update_loop

    .complete:
        ; Old tail position is the return value now.
        mov eax, r15d

        ; Restore non-volatile regs.
        mov r15, [rbp - 40]
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Wrapper function, which handles the unit update. It first updates the position depending on its active direction.
; Afterwards it is changing the direction into it's new direction passed from the unit above.
_update_unit:
    ; * Expect pointer to unit object in RCX.
    ; * Expect direction in DL.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Save params into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], dl

    .update_position:
        call _update_unit_position

    .update_direction:
        mov rcx, [rbp + 16]
        mov dl, [rbp + 24]
        call _update_unit_direction

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_update_unit_position:
    ; * Expect pointer to unit in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Prepare unit.
        mov rdx, [rcx + unit.position_ptr]

        ; Prepare movement table.
        lea rax, [rel .movement_table]

        ; Prepare active unit direction.
        movzx r8, byte [rcx + unit.direction]
        
        mov rax, [rax + r8*8]
        jmp rax
    
    .movement_table:
        dq .move_left
        dq .move_up
        dq .move_right
        dq .move_down

    ; Update position.
    .move_left:
        dec word [rdx + position.x]
        jmp .complete
    .move_up:
        dec word [rdx + position.y]
        jmp .complete
    .move_right:
        inc word [rdx + position.x]
        jmp .complete
    .move_down:
        inc word [rdx + position.y]

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_update_unit_direction:
    ; * Expect pointer to unit object in RCX.
    ; * Expect new direction in DL.
    mov [rcx + unit.direction], dl
    ret




;;;;;; COLLISSION CHECK METHODS ;;;;;;

; Simple wrapper function, which gatheres all the collission checks and calls them.
_collission_check:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .check_collission:
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

; Checking the snake collission by comparing the head position with the position of every unit.
; ! There also must be a better way to check that instead of looping through the whole list every time again.
_check_snake_collission:
    .set_up:
        ; Set up stack frame:
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14

    .set_up_loop_base:
        ; I am setting up the base for the collission check loop:
        ; * - RBX is going to be the tail pointer. After every iteration, I will check, if the tail is reached.
        ; * - R12 is the active unit getting updated.
        ; * - R13D will hold the position of the head.
        ; * - R14D will hold the position of the active unit.
        mov rbx, [rel lcl_game_ptr]
        mov rbx, [rbx + game.board_ptr]
        mov rbx, [rbx + board.snake_ptr]
        mov r12, [rbx + snake.head_ptr]
        mov r12, [r12 + unit.position_ptr]

        ; Save X-Position of active unit.
        mov r13w, [r12 + position.x]           
        shl r13, 16
        ; Save Y-Position of active unit.
        mov r13w, [r12 + position.y]

        ; The first unit to be checked is the fourth unit after head.
        mov r12, [rbx + snake.head_ptr]
        mov rcx, 3
    .loop:
        mov r12, [r12 + unit.next_unit_ptr]
        loop .loop

        ; RBX is the tail now.
        mov rbx, [rbx + snake.tail_ptr]

    .collission_check_loop:
        mov rcx, [r12 + unit.position_ptr]
        mov r14w, [rcx + position.x]
        shl r14, 16
        mov r14w, [rcx + position.y]
        cmp r14d, r13d
        je .game_over

    .collission_check_loop_handle:
        cmp r12, rbx
        je .game_on
        mov r12, [r12 + unit.next_unit_ptr]
        jmp .collission_check_loop

    .game_over:
        mov rax, 1
        jmp .complete

    .game_on:
        xor rax, rax

    .complete:
        ; Restore non-volatile regs.
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Wall collission is simply checking if head is exceeding the boundaries of the board dimensions.
_check_wall_collission:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

    .set_up_head_position:
        mov rcx, [rel lcl_game_ptr]
        mov rcx, [rcx + game.board_ptr]
        mov rdx, [rcx + board.snake_ptr]
        mov rdx, [rdx + snake.head_ptr]
        mov rdx, [rdx + unit.position_ptr]

    .compare_x:
        cmp word [rdx + position.x], 0
        jb .game_over
        mov r9w, [rcx + board.width]
        cmp [rdx + position.x], r9w
        ja .game_over

    .compare_y:
        cmp word [rdx + position.y], 0
        jb .game_over
        mov r9w, [rcx + board.height]
        cmp [rdx + position.y], r9w
        ja .game_over

    .game_on:
        mov rax, 0
        jmp .complete

    .game_over:
        mov rax, 1

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Food collission checks if the head position is same with the food position. Also simple.
_check_food_collission:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

    .set_up_board:
        mov rcx, [rel lcl_game_ptr]
        mov rcx, [rcx + game.board_ptr]
        mov r8, [rcx + board.food_ptr]

    .set_up_food_position:
        mov r8, [r8 + food.position_ptr]
        mov r9w, [r8 + position.x]
        shl r9, 16
        mov r9w, [r8 + position.y]

    .set_up_head_position:
        mov r8, [rcx + board.snake_ptr]
        mov r8, [r8 + snake.head_ptr]
        mov r8, [r8 + unit.position_ptr]
        mov r10w, [r8 + position.x]
        shl r10, 16
        mov r10w, [r8 + position.y]

    .compare:
        cmp r9d, r10d
        je .food_collission

    .no_food_collission:
        xor rax, rax
        jmp .complete

    .food_collission:
        mov rax, 2

    .complete:
        ; Returning the value if collission (2) or no collission (0)in RAX.
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; SCOREBOARD METHODS ;;;;;;

; I wanted to print the lvl top left, the best top right, player name bottom left and score at the bottom right.
; This is a wrapper function gathering all the print functions to succeed that goal.
_build_scoreboard:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If game is not created, let the user know.
        cmp qword [rel lcl_game_ptr], 0
        je _g_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .call_functions: 
        call _print_points
        call _print_level
        call _print_player
        call _print_highscore

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_print_player:
    .set_up:
        ; Set up stack frame:
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Save non volatile regs.
        mov [rbp - 8], rbx 
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14

        ; Prepare game pointer in RBX.
        mov rbx, [rel lcl_game_ptr]

        ; Prepare board pointer in R13.
        mov r13, [rbx + game.board_ptr]

        ; Prepare board.getter_table in R14.
        mov r14, [r13 + board.getter_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    ; I want to place the player on the left bottom corner below the board.
    ; R12D will hold the X- and the Y-coordinates of the starting point.
    .get_x_offset:
        ; So I get the X-Offset of the board.
        call [r14 + BOARD_GETTER_VTABLE_X_OFFSET]
        ; Prepare X value in R12W.
        mov r12w, ax
        dec r12w
        shl r12d, 16

    .get_y_offset:
        ; Get Y-Offset of the board.
        call [r14 + BOARD_GETTER_VTABLE_Y_OFFSET]
        ; Prepare Y value in R12W.
        mov r12w, ax
        add r12w, [r13 + board.height]
        add r12w, 2

    ; Find out, how many bytes have to been written.
    .get_name_length:
        call get_player_name_length
        ; Prepare 3 parameter for write function. (Amount of bytes to write)
        mov r8, rax

    .write_name:
        mov ecx, r12d
        mov rdx, [rbx + game.options_ptr]
        mov rdx, [rdx + options.player_ptr]
        mov rdx, [rdx + player.name]
        xor r9, r9 
        call console_manager_write_word

    .complete:
        ; Restore non-volatile regs.
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_print_level:
    .set_up:
        ; Set up stack frame:
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non-volatile regs.
        mov [rbp - 8], r12
        mov [rbp - 16], r13

        ; Prepare the board.getter_table in R13.
        mov r13, [rel lcl_game_ptr]
        mov r13, [r13 + game.board_ptr]
        mov r13, [r13 + board.getter_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    ; I want to place the level on the left top corner above the board.
    ; R12D will hold the X- and the Y-coordinates of the starting point.
    .get_x_offset:
        ; So I get the X-Offset of the board.
        call [r13 + BOARD_GETTER_VTABLE_X_OFFSET]

        ; Prepare X value in R12W.
        mov r12w, ax
        dec r12w
        shl r12d, 16

    .get_y_offset:
        ; Get Y-Offset of the board.
        call [r13 + BOARD_GETTER_VTABLE_Y_OFFSET]
        ; Prepare Y value in R12W.
        mov r12w, ax
        sub r12w, 2

    .write_word:
        mov ecx, r12d
        lea rdx, [rel lvl_format]
        mov r8, LVL_LENGTH
        xor r9, r9
        call console_manager_write_word

    .change_position:
        mov ecx, r12d
        mov rdx, LVL_LENGTH
        xor r8, r8
        call helper_change_position

    .write_lvl:
        mov ecx, eax
        mov rdx, [rel lcl_game_ptr]
        mov rdx, [rdx + game.options_ptr]
        mov edx, [rdx + options.lvl]
        mov r8, 2
        call console_manager_write_number

    .complete:
        ; Restore non-volatile regs.
        mov r13, [rbp - 16]
        mov r12, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_print_points:
    .set_up:
        ; Set up stack frame:
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Save non volatile regs.
        mov [rbp - 8], rbx 
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14

        ; Prepare game pointer in RBX.
        mov rbx, [rel lcl_game_ptr]

        ; Prepare board pointer in R13.
        mov r13, [rbx + game.board_ptr]

        ; Prepare the board.getter_table in R14.
        mov r14, [r13 + board.getter_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    ; I want to place the points on the right bottom corner below the board.
    ; R12D will hold the X- and the Y-coordinates of the starting point.
    .get_x_offset:
        ; So I get the X-Offset of the board.
        call [r14 + BOARD_GETTER_VTABLE_X_OFFSET]

        ; Prepare X value in R12W.
        mov r12w, ax
        add r12w, [r13 + board.width]
        sub r12w, 2
        shl r12d, 16

    .get_y_offset:
        ; Get Y-Offset of the board.
        call [r14 + BOARD_GETTER_VTABLE_Y_OFFSET]

        ; Prepare Y value in R12W.
        mov r12w, ax
        add r12w, [r13 + board.height]
        add r12w, 2

    .write_points:
        mov ecx, r12d
        mov edx, [rbx + game.points]
        mov r8, 4
        call console_manager_write_number

    .complete:
        ; Restore non-volatile regs.
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_print_highscore:
    .set_up:
        .set_up:
        ; Set up stack frame:
        ; * 24 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Save non volatile regs.
        mov [rbp - 8], rbx 
        mov [rbp - 16], r12
        mov [rbp - 24], r13

        ; Prepare game pointer in RBX.
        mov rbx, [rel lcl_game_ptr]

        ; Prepare board pointer in R13.
        mov r13, [rbx + game.board_ptr]

        ; Prepare the board.getter_table in R14.
        mov r14, [r13 + board.getter_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    ; I want to place the highscore on the left top corner above the board.
    ; R12D will hold the X- and the Y-coordinates of the starting point.
    .get_x_offset:
        ; So I get the X-Offset of the board.
        call [r14 + BOARD_GETTER_VTABLE_X_OFFSET]

        ; Prepare X value in R12W.
        mov r12w, ax
        add r12w, [r13 + board.width]
        sub r12w, BEST_LENGTH + 2
        shl r12d, 16

    .get_y_offset:
        ; Get Y-Offset of the board.
        call [r14 + BOARD_GETTER_VTABLE_Y_OFFSET]
        ; Prepare Y value in R12W.
        mov r12w, ax
        sub r12w, 2

    .write_word:
        mov ecx, r12d
        lea rdx, [rel best_format]
        mov r8, BEST_LENGTH
        xor r9, r9
        call console_manager_write_word

    .change_position:
        mov ecx, r12d
        mov rdx, BEST_LENGTH
        xor r8, r8
        call helper_change_position

    .write_number:
        mov ecx, eax
        mov rdx, [rbx + game.options_ptr]
        mov rdx, [rdx + options.player_ptr]
        mov edx, [rdx + player.highscore]
        mov r8, 4
        call console_manager_write_number

    .complete:
        ; Restore non-volatile regs.
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; AFTER GAME METHODS ;;;;;;

; A wrapper function to handle the mechanics if the game is over.
_game_over:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .game_over_sequence:
        lea rcx, [rel game_over_table]
        mov rdx, game_over_table_size
        xor r8, r8
        call designer_type_sequence

        mov rcx, 2000
        call Sleep

    .highscore_update:
        call _update_highscore

    .complete:
        ; Resotre old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Mechanic to possibly update the highscore of the player.
_update_highscore:
    .set_up:
        ; Set up stack frame:
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Set up game pointer in RBX.
        mov rbx, [rel lcl_game_ptr]

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .add_bonus_points:
        call _add_bonus_points

        ; Set up game points in ECX.
        mov ecx, [rbx + game.points]

        ; Set up player pointer in RBX.
        mov rbx, [rbx + game.options_ptr]
        mov rbx, [rbx + options.player_ptr]

    .compare_points_and_highscore:
        ; Set up highscore in EDX.
        mov edx, [rbx + player.highscore]

        cmp ecx, edx
        jbe .complete

    .update_highscore:
        call player_update_highscore

        mov rcx, [rbx + player.name]
        call file_manager_get_name

        mov rdx, rax
        mov ecx, dword [rbx + player.highscore]
        call file_manager_update_highscore

    .complete:
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_add_bonus_points:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

    ; Board area in RAX.
    .set_up_board_area:
        mov rcx, [rel lcl_game_ptr]
        mov rcx, [rcx + game.board_ptr]
        movzx rax, word [rcx + board.width]
        movzx rdx, word [rcx + board.height]
        mul rdx

    ; Snake length in RDX.
    .set_up_snake_length:
        mov rdx, [rcx + board.snake_ptr]
        mov rdx, [rdx + snake.length]

    ; If snake length is as big as area, add 100 points bonus.
    .compare:
        cmp rdx, rax
        jb .complete

    .add_bonus_points:
        add dword [rcx + game.points], 100

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; KEY PRESS REQUESTS ;;;;;;

; Checking the states of the arrow keys.
_request_direction_change:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    ; 25H is the number of the left arrow key.
    .check_left:
        mov rcx, 25h
        call GetAsyncKeyState
        test rax, 8001h
        jnz .go_left

    ; 26H is the number of the up arrow key.
    .check_up:
        mov rcx, 26h
        call GetAsyncKeyState
        test rax, 8001h
        jnz .go_up

    ; 27H is the number of the right arrow key.
    .check_right:
        mov rcx, 27h
        call GetAsyncKeyState
        test rax, 8001h
        jnz .go_right

    ; 28H is the number of the down arrow key.
    .check_down:
        mov rcx, 28h
        call GetAsyncKeyState
        test rax, 8001h
        jnz .go_down

        jmp .complete

    ; If the snake is not going right at the moment, let it go left now.
    .go_left:
        cmp qword [rel current_direction], 2
        je .complete
        mov qword [rel current_direction], 0
        jmp .complete

    ; If the snake is not going down at the moment, let it go up now.
    .go_up:
        cmp qword [rel current_direction], 3
        je .complete
        mov qword [rel current_direction], 1
        jmp .complete

    ; If the snake is not going left at the moment, let it go right now.
    .go_right:
        cmp qword [rel current_direction], 0
        je .complete
        mov qword [rel current_direction], 2
        jmp .complete

    ; If the snake is not going up at the moment, let it go down now.
    .go_down:
        cmp qword [rel current_direction], 1
        je .complete
        mov qword [rel current_direction], 3

    .complete:
        ; Return new direction in RAX.
        mov rax, qword [rel current_direction]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_request_pause:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    ; 50H is the "P" key.
    .check_pause:
        mov rcx, 50h
        call GetAsyncKeyState
        test rax, 1

        jz .complete

    .check_if_paused:
        cmp byte [rel is_paused], 1
        je .pause_stop

    .pause:
        mov byte [rel is_paused], 1
        jmp .complete

    .pause_stop:
        mov byte [rel is_paused], 0

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; ERROR HANDLING ;;;;;;
_g_malloc_failed:
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

_g_object_failed:
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

_u_direction_error:
    ; * Expect pointer to unit object in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .debug:
        mov rdx, rcx
        movzx rdx, byte [rdx + unit.direction]
        lea rcx, [rel direction_error]
        call printf

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret