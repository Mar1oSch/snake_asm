; Constants:
%include "./include/data/organizer/interactor_constants.inc"
%include "./include/data/game/game_constants.inc"
%include "./include/data/game/player/player_constants.inc"
%include "./include/data/game/options/options_constants.inc"

; Data:
%include "./include/data/organizer/interactor_strings.inc"

; Strucs:
%include "./include/strucs/organizer/interactor_struc.inc"
%include "./include/strucs/organizer/file_manager_struc.inc"
%include "./include/strucs/organizer/table/table_struc.inc"
%include "./include/strucs/game/game_struc.inc"
%include "./include/strucs/game/player_struc.inc"
%include "./include/strucs/game/options_struc.inc"

; This is the interactor, which is simply managing all the interaction with the user. It is the only object visible to the main function of the program.
; It is handling the player and game creation and managing every option after the game.

global interactor_new, interactor_setup, interactor_create_game, interactor_start_game, interactor_destroy, interactor_replay_game

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "interactor_new", 0

section .bss
    ; Memory space for the created interactor pointer.
    ; Since there is always just one interactor in the game, I decided to create a kind of a singleton.
    ; If this lcl_interactor_ptr is 0, the constructor will create a new interactor object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_interactor_ptr resq 1

    ; Preserved memory space for the player name which will be entered in user input.
    lcl_player_name resb PLAYER_NAME_LENGTH

    ; Local player struc to recieve the information from the leaderboard and create the player object based on that struc.
    player_from_file_struc:
        .name resb PLAYER_NAME_LENGTH
        .highscore resd 1
    player_from_file_struc_end:

section .text
    extern malloc, free
    extern Sleep

    extern console_manager_recieve_literal_input, console_manager_recieve_numeral_input, console_manager_clear_all, console_manager_set_console_cursor_info
    extern designer_new, designer_start_screen, designer_type_sequence, designer_write_table, designer_write_headline
    extern game_new
    extern file_manager_new, file_manager_add_leaderboard_record, file_manager_get_record_by_index, file_manager_get_num_of_entries, file_manager_get_name, file_manager_get_total_bytes, file_manager_create_table_from_file, file_manager_update_table
    extern player_new
    extern helper_get_digits_of_number, helper_get_digits_in_string, helper_parse_saved_to_int
    extern options_new

    extern malloc_failed, object_not_created

;;;;;; PUBLIC METHODS ;;;;;;

; The constructor of the interactor. It is constructing all of the other needed organizers in a cascade as well.
interactor_new:
    .set_up:
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp

        ; Check if a game already exists. If yes, return the pointer to it.
        cmp qword [rel lcl_interactor_ptr], 0
        jne .complete

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .create_object:
        ; Creating the interactor itself, containing space for:
        ; * - Game pointer. (8 bytes)
        ; * - Table pointer. (8 bytes)
        ; * - Designer pointer. (8 bytes)
        ; * - File manager pointer. (8 bytes)
        mov rcx, interactor_size
        call malloc
        ; Pointer to interactor object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _i_malloc_failed

        ; Save pointer to initially reserved space. Object is "officially" created now.
        mov [rel lcl_interactor_ptr], rax

        ; Save pointer to RBX, to set the object up.
        mov rbx, rax

    .create_dependend_objects:
        call designer_new
        mov [rbx + interactor.designer_ptr], rax

        call file_manager_new
        mov [rbx + interactor.file_manager_ptr], rax

    .complete:
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Use the pointer to the game object as return value of this constructor.
        mov rax, qword [rel lcl_interactor_ptr]
        
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Simple destructor to free memory space.
interactor_destroy:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .destroy_object:
        ; Use the local lcl_interactor_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_interactor_ptr]
        call free
        mov qword [rel lcl_interactor_ptr], 0

    .complete:
        ; Restore old stack frame and leave destructor.
        mov rsp, rbp
        pop rbp
        ret

; This method is setting up the introduction and checks, if user wants to create new player or choose a created player.
interactor_setup:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .start_screen:
        ; Showing the "SNAKE" screen for 1 second.
        call designer_start_screen
        mov rcx, 1000
        call Sleep

    .clear_screen:
        call console_manager_clear_all

    .cursor_visibility:
        ; Let console cursor be visible.
        mov ecx, 1
        call console_manager_set_console_cursor_info

    .new_or_file_player_dialogue:
        call _new_or_file_player

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Here the game object gets created by user inputs.
interactor_create_game:
    ; * Expect 0 if player should be loaded or 1 if new player should be created in RCX.
    .set_up:
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .create_player:
        call _create_player
        ; * First local variable: Player pointer.
        mov [rbp - 8], rax

    .create_level:
        lea rcx, [rel level_creation_table]
        mov rdx, level_creation_table_size
        call _get_level

    .create_options:
        ; Use the created player and level to set up the options for the game.
        mov rcx, [rbp - 8]
        mov rdx, rax
        call options_new
        ; * Use first local variable: Options pointer.
        mov [rbp - 8], rax

    .create_game:
        ; Set up the width and height of the board in ECX.
        ; (The plan was to also make the board user dependend. But then the highscore wouldn't make sense anymore.)
        mov cx, DEFAULT_BOARD_WIDTH
        shl ecx, 16
        mov cx, DEFAULT_BOARD_HEIGHT

        ; Pass the options pointer in RDX.
        mov rdx, [rbp - 8]

        ; And the interactor in R8.
        mov r8, [rel lcl_interactor_ptr]

        call game_new

    .set_up_object:
        ; Move the created game into the preserved memory space.
        mov rcx, [rel lcl_interactor_ptr]
        mov [rcx + interactor.game_ptr], rax

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; After creating the game, the game is ready to start.
; The interactor is managing it.
interactor_start_game:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .call_functions:
        ; Make console cursor invisible.
        xor ecx, ecx
        call console_manager_set_console_cursor_info

        mov r10, [rel lcl_interactor_ptr]
        mov r10, [r10 + interactor.game_ptr]
        mov r10, [r10 + game.methods_vtable_ptr]
        call [r10 + GAME_METHODS_VTABLE_START_OFFSET]

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


interactor_replay_game:
    .set_up:
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Make RBX to game pointer.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.game_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .restart_loop:
        ; Make cursor visible.
        mov ecx, 1
        call console_manager_set_console_cursor_info

        ; Change options.
        mov rcx, [rbx + game.options_ptr]
        call _handle_options

        ; If user chooses to exit game, break loop.
        test rax, rax
        jz .complete

        ; * First local variables: Option pointer.
        mov [rbp - 16], rax

        ; Make cursor invisible.
        xor ecx, ecx
        call console_manager_set_console_cursor_info

        ; Reset game with new options.
        mov rcx, [rbp - 16]

    .reset_game:
        ; Make RBX point to the game methods vtable.
        mov rbx, [rbx + game.methods_vtable_ptr]
        call [rbx + GAME_METHODS_VTABLE_RESET_OFFSET]

    .start_game:
        ; Start game.
        call [rbx + GAME_METHODS_VTABLE_START_OFFSET]

        jmp .restart_loop

    .complete:
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; PRIVATE METHODS ;;;;;;
_new_or_file_player:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        ; Clear console before writing new sequence.
        call console_manager_clear_all

    .new_or_file_player:
        lea rcx, [rel new_or_file_player_table]
        mov rdx, new_or_file_player_table_size
        mov r8, 0
        call designer_type_sequence

    .check_for_answer:
        call _get_yes_no

    .complete:
        ; Return answer in RAX.
        ; 0 if "No" => Create player from file.
        ; 1 if "Yes" => Create new player.

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; The wrapper function to create a player.
; Either a new one or from the leaderboard.
_create_player:
    ; * Expect 0 if player should be loaded or 1 if new player should be created in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save params into shadow space.
        mov [rbp + 16], rcx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .check_for_players:
        ; If the leaderboard doesn't contain any player, create a new one.
        call file_manager_get_num_of_entries
        test rax, rax
        jz .create_new_player
    
    .get_player_creation:
        cmp qword [rbp + 16], 0
        jne .create_new_player

    .create_file_player:
        call _create_player_from_file
        jmp .complete

    .create_new_player:
        call _create_new_player

    .complete:
        mov rsp, rbp
        pop rbp
        ret

_change_player:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32
    
    .destroy_old_player:
        mov r10, [rel lcl_interactor_ptr]
        mov r10, [r10 + interactor.game_ptr]
        mov r10, [r10 + game.options_ptr]
        mov r10, [r10 + options.player_ptr]
        mov r10, [r10 + player.methods_vtable_ptr]
        call [r10 + PLAYER_METHODS_VTABLE_DESTRUCTOR_OFFSET]

    .clear_screen:
        call console_manager_clear_all

    .change_dialogue:
        lea rcx, [rel player_change_table]
        mov rdx, player_change_table_size
        xor r8, r8
        call designer_type_sequence

    .get_player_creation:
        call _get_yes_no

        test rax, rax
        jnz .change_new_player

    .change_existing_player:
        call _create_player_from_file
        jmp .complete

    .change_new_player:
        call _create_new_player

    .complete:
        ; Return pointer to new player in RAX.

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_create_player_from_file:
    .set_up:
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        call console_manager_clear_all

    .write_headline:
        lea rcx, [rel file_player_headline]
        mov rdx, file_player_headline_length
        call designer_write_headline

    .show_leaderboard:
        call _show_leaderboard

    .check_for_entries:
        call file_manager_get_num_of_entries
        mov rbx, rax

    .get_index_loop:
        mov rcx, rax
        call _get_player_index
        cmp rax, rbx
        ja .get_index_loop
        cmp rax, 0
        jb .get_index_loop
    
    .create_player_from_index:
        mov rcx, rax
        call _create_player_from_index

    .complete:
        ; Return pointer to created player in RAX.

        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_create_new_player:
    .set_up:
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        call console_manager_clear_all

    .get_name:
        lea rcx, [rel new_player_table]
        mov rdx, new_player_table_size
        mov r8, 0
        call designer_type_sequence

        call _get_player_name

    .create_player:
        lea rcx, [rel lcl_player_name]
        xor rdx, rdx
        call player_new

        ; * First local variable: Player pointer.
        mov [rbp - 8], rax

    .add_player_to_file:
        lea rcx, [rel lcl_player_name]
        xor rdx, rdx
        call file_manager_add_leaderboard_record

    .complete:
        ; Return created player in RAX.
        mov rax, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_show_leaderboard:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .update_leaderboard:
        call file_manager_update_table

    .write_leaderboard:
        mov rcx, rax
        call designer_write_table

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_get_player_index:
    ; * Expect num of entries in RCX.
    .set_up:
        ; Set up stack frame.
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12

        ; Save num of entries in RBX.
        mov rbx, rcx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .get_digits:
        call helper_get_digits_of_number
        mov r12, rax

    .loop:
        mov rcx, r12
        call console_manager_recieve_numeral_input
        cmp rax, rbx
        ja .loop
        cmp rax, 1
        jb .loop

    .complete:
        ; Decrement RAX, so it is the actual index and return it.
        dec rax

        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_create_player_from_index:
    ; * Expect index of player in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .get_player_record:
        mov rdx, rcx
        lea rcx, [rel player_from_file_struc]
        call file_manager_get_record_by_index

    .parse_highscore:
        lea rcx, [rel player_from_file_struc + 16]
        mov rdx, 4
        call helper_parse_saved_to_int

    .create_player:
        lea rcx, [rel player_from_file_struc]
        mov rdx, rax
        call player_new

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_get_player_name:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .name_loop:
        lea rcx, [rel lcl_player_name]
        mov rdx, PLAYER_NAME_LENGTH - 1
        call console_manager_recieve_literal_input

        ; Zero out the memory space which is not used.
        call _clear_player_name

        ; It is not valid if name already exists.
        lea rcx, [rel lcl_player_name]
        call file_manager_get_name
        cmp rax, -1
        jne .name_loop

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_get_level:
    ; * Expect pointer to string table in RCX.
    ; * Expect size of table in RDX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save params into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], rdx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        call console_manager_clear_all

    .level_creation_dialogue:
        mov rcx, [rbp + 16]
        mov rdx, [rbp + 24]
        xor r8, r8
        call designer_type_sequence

    .level_loop:              
        mov rcx, 1
        call console_manager_recieve_numeral_input
        cmp rax, 9
        ja .level_loop
        cmp rax, 1
        jb .level_loop

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_show_options_table:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        call console_manager_clear_all

    .show_options:
        lea rcx, [rel after_game_table]
        mov rdx, after_game_table_size
        xor r8, r8
        call designer_type_sequence

    .complete:
        mov rsp, rbp
        pop rbp
        ret

_handle_options:
    ; * Expect pointer to old options in RCX.
    .set_up:
        ; Set up stack frame.
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12

        ; Make RBX point to old options object.
        mov rbx, rcx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .options_loop:
        ; Clearing the screen.
        call console_manager_clear_all

        ; Showing the options table.
        call _show_options_table

        ; Get one byte numeral input.
        mov rcx, 1
        call console_manager_recieve_numeral_input

        ; Check if RAX is in bounds of options.
        cmp rax, 1
        jb .options_loop
        cmp rax, OPTIONS_LENGTH
        ja .options_loop

    .prepare_options_handle:
        lea rdx, [rel .options_table]
        dec rax
        mov rax, [rdx + rax * 8]
        jmp rax

    .options_table:
        dq .handle_replay
        dq .handle_change_player
        dq .handle_change_level
        dq .handle_change_both
        dq .handle_show_leaderboard
        dq .handle_exit

    .handle_replay:
        ; No changes. Old Options are new options.
        mov rax, rbx
        jmp .complete

    .handle_change_player:
        ; Creating a new player.
        call _change_player

        ; Creating new options, based on the new player.
        mov rcx, rax
        mov edx, [rbx + options.lvl]
        call options_new
        mov r12, rax

        ; Destroying the old options object.
        mov rcx, rbx
        mov r10, [rcx + options.methods_vtable_ptr]
        call [r10 + OPTIONS_METHODS_VTABLE_DESTRUCTOR_OFFSET]

        ; Returning the new options object in RAX.
        mov rax, r12
        jmp .complete

    .handle_change_level:
        ; Let the user choose the new level.
        lea rcx, [rel level_change_table]
        mov rdx, level_change_table_size
        call _get_level

        ; Creationg new options, based on the new level.
        mov rcx, [rbx + options.player_ptr]
        mov rdx, rax
        call options_new
        mov r12, rax

        ; Destroying the old options object.
        mov rcx, rbx
        mov r10, [rcx + options.methods_vtable_ptr]
        call [r10 + OPTIONS_METHODS_VTABLE_DESTRUCTOR_OFFSET]

        ; Returning the new options object in RAX.
        mov rax, r12
        jmp .complete

    .handle_change_both:
        ; Creating a new player.
        call _change_player
        mov r12, rax

        ; Let the user choose the new level.
        lea rcx, [rel level_change_table]
        mov rdx, level_change_table_size
        call _get_level
        mov rdx, rax

        ; Create new options, based on new player and new level.
        mov rcx, r12
        mov rdx, rax
        call options_new
        mov r12, rax

        ; Destroy old options object.
        mov rcx, rbx
        mov r10, [rcx + options.methods_vtable_ptr]
        call [r10 + OPTIONS_METHODS_VTABLE_DESTRUCTOR_OFFSET]

        ; Return new options object in RAX.
        mov rax, r12
        jmp .complete

    .handle_show_leaderboard:
        ; Clear screen.
        call console_manager_clear_all

        ; Write headline of leaderboard.
        lea rcx, [rel leaderboard_headline]
        mov rdx, leaderboard_headline_length
        call designer_write_headline

        ; Showing the leaderboard.
        call _show_leaderboard

        ; Waiting for a "Enter" of the user.
        lea rcx, [rbp - 24]
        mov rdx, 1
        call console_manager_recieve_literal_input

        ; Go back to after game screen.
        jmp .options_loop

    .handle_exit:
        ; Exit the game.
        xor rax, rax

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        mov rsp, rbp
        pop rbp
        ret

_get_yes_no:
    .set_up:
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .yes_no_loop:
        ; Get one byte input.
        lea rcx, [rbp - 8]
        mov rdx, 1
        call console_manager_recieve_literal_input

        ; Check if input is a "Y" or a "N"
        mov al, [rbp - 8]
        and al, 0xDF
        cmp al, "Y"
        je .yes
        cmp al, "N"
        je .no

        ; If not loop again.
        jmp .yes_no_loop

    .yes:
        ; Return 1 in RAX.
        mov rax, 1
        jmp .complete

    .no:
        ; Return 0 in RAX.
        xor rax, rax

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


_clear_player_name:
.set_up:
    ; No stack frame required.
    ; No local variables.
    ; No function calls.

    ; Prepare name and its length.
    mov rcx, PLAYER_NAME_LENGTH
    lea rdx, [rel lcl_player_name]

    ; Last value of name is 0.
    mov byte [rdx + rcx], 0

; Loop through the name and change all values, which are not part of it to 0.
; If the loop is facing a 10 (Carriage Return) or a 13 (Line Feed), it knows, that these signs are the first values after the name. So it is handling them specially.
.clearing_loop:
    cmp byte [rdx + rcx], 10
    je .clear_cr
    cmp byte [rdx + rcx], 13
    je .clear_lf
    loop .clearing_loop
    jmp .complete

.clear_cr:
    dec rcx
    mov word [rdx + rcx], 0
    jmp .complete

.clear_lf:
    mov byte [rdx + rcx], 0

.complete:
    ; Return to caller.
    ret



;;;;;; ERROR HANDLING ;;;;;;
_i_malloc_failed:
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

_i_object_failed:
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