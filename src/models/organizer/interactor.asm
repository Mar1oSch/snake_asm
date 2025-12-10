; Constants:
%include "./include/data/organizer/console_manager/console_manager_constants.inc"
%include "./include/data/organizer/designer/designer_constants.inc"
%include "./include/data/organizer/file_manager/file_manager_constants.inc"
%include "./include/data/organizer/interactor/interactor_constants.inc"
%include "./include/data/game/game_constants.inc"
%include "./include/data/game/player/player_constants.inc"
%include "./include/data/game/options/options_constants.inc"

; Data:
%include "./include/data/organizer/interactor/interactor_strings.inc"

; Strucs:
%include "./include/strucs/organizer/console_manager_struc.inc"
%include "./include/strucs/organizer/designer_struc.inc"
%include "./include/strucs/organizer/file_manager_struc.inc"
%include "./include/strucs/organizer/table/table_struc.inc"
%include "./include/strucs/organizer/interactor_struc.inc"
%include "./include/strucs/game/game_struc.inc"
%include "./include/strucs/game/player_struc.inc"
%include "./include/strucs/game/options_struc.inc"

; This is the interactor, which is simply managing all the interaction with the user. It is the only object visible to the main function of the program.
; It is handling the player and game creation and managing every option after the game.

global interactor_new

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
    lcl_i_player_name resb PLAYER_NAME_LENGTH

    ; Local player struc to recieve the information from the leaderboard and create the player object based on that struc.
    player_from_file_struc:
        .name resb PLAYER_NAME_LENGTH
        .highscore resd 1
    player_from_file_struc_end:

section .text
    extern malloc, free
    extern Sleep

    extern designer_new
    extern game_new
    extern file_manager_new
    extern player_new
    extern helper_get_digits_of_number, helper_get_digits_in_string, helper_parse_saved_to_int
    extern options_new

    extern malloc_failed, object_not_created

;;;;;; VTABLES ;;;;;;
interactor_methods_vtable:
    dq interactor_setup
    dq interactor_create_game
    dq interactor_start_game
    dq interactor_replay_game
    dq interactor_update_player_highscore_in_file
    dq interactor_destroy

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

    .set_up_tables:
        lea rcx, [rel interactor_methods_vtable]
        mov [rbx + interactor.methods_vtable_ptr], rcx

    .complete:
        ; Use the pointer to the game object as return value of this constructor.
        mov rax, qword [rel lcl_interactor_ptr]
        
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

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

        ; Prepare designer pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.designer_ptr]

        ; Prepare designer.methods_table in R10.
        mov r10, [rbx + designer.methods_vtable_ptr]

        ; Prepare console_manager pointer in RBX.
        mov rbx, [rbx + designer.console_manager_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .start_screen:
        ; Showing the "SNAKE" screen for 1 second.
        call [r10 + DESIGNER_METHODS_START_SCREEN_OFFSET]
        mov rcx, 1000
        call Sleep

    .clear_screen:
        mov r10, [rbx + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .cursor_visibility:
        ; Let console cursor be visible.
        mov ecx, 1
        mov r10, [rbx + console_manager.setter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_SETTER_CURSOR_INFO_OFFSET]

    .new_or_file_player_dialogue:
        call _new_or_file_player

    .complete:
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

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

        ; Prepare console_manager pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.designer_ptr]
        mov rbx, [rbx + designer.console_manager_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        mov r10, [rbx + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .call_functions:
        ; Make console cursor invisible.
        xor ecx, ecx
        mov r10, [rbx + console_manager.setter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_SETTER_CURSOR_INFO_OFFSET]

        mov r10, [rel lcl_interactor_ptr]
        mov r10, [r10 + interactor.game_ptr]
        mov r10, [r10 + game.methods_vtable_ptr]
        call [r10 + GAME_METHODS_START_OFFSET]

    .complete:
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


interactor_replay_game:
    .set_up:
        ; Set up stack frame.
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13

        ; Prepare interactor pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]

        ; Prepare console_manager in R12.
        mov r12, [rbx + interactor.designer_ptr]
        mov r12, [r12 + designer.console_manager_ptr]

        ; Prepare game pointer in RBX.
        mov rbx, [rbx + interactor.game_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .restart_loop:
        ; Make cursor visible.
        mov ecx, 1
        mov r10, [r12 + console_manager.setter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_SETTER_CURSOR_INFO_OFFSET]

        ; Change options.
        mov rcx, [rbx + game.options_ptr]
        call _handle_options

        ; If user chooses to exit game, break loop.
        test rax, rax
        jz .complete

        ; * First local variable: Option pointer.
        mov [rbp - 32], rax

        ; Make cursor invisible.
        xor ecx, ecx
        mov r10, [r12 + console_manager.setter_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_SETTER_CURSOR_INFO_OFFSET]

    .reset_game:
        ; Clear screen.
        mov r10, [r12 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

        ; Make R13 point to the game methods vtable.
        mov r13, [rbx + game.methods_vtable_ptr]
        ; Reset game with new options.
        mov rcx, [rbp - 32]
        call [r13 + GAME_METHODS_RESET_OFFSET]

    .start_game:
        ; Start game.
        call [r13 + GAME_METHODS_START_OFFSET]

        jmp .restart_loop

    .complete:
        ; Restore non-volatile regs.
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

interactor_update_player_highscore_in_file:
    ; * Expect player pointer in RCX.
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

        ; Prepare file_manager pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.file_manager_ptr]

        ; Save player pointer into R12.
        mov r12, rcx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .update_file_highscore:
        mov rcx, [r12 + player.name]
        mov r10, [rbx + file_manager.getter_vtable_ptr]
        call [r10 + FILE_MANAGER_GETTER_NAME_OFFSET]

        mov rdx, rax
        mov ecx, [r12 + player.highscore]
        mov r10, [rbx + file_manager.methods_vtable_ptr]
        call [r10 + FILE_MANAGER_METHODS_UPDATE_HIGHSCORE_OFFSET]

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret



;;;;;; PRIVATE METHODS ;;;;;;
_new_or_file_player:
    .set_up:
        ; Set up stack frame without.
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

        ; Prepare designer pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.designer_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        ; Clear console before writing new sequence.
        mov r10, [rbx + designer.console_manager_ptr]
        mov r10, [r10 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .new_or_file_player:
        lea rcx, [rel new_or_file_player_table]
        mov rdx, new_or_file_player_table_size
        xor r8, r8
        mov r10, [rbx + designer.methods_vtable_ptr]
        call [r10 + DESIGNER_METHODS_TYPE_SEQUENCE_OFFSET]

    .check_for_answer:
        call _get_yes_no

    .complete:
        ; Return answer in RAX.
        ; 0 if "No" => Create player from file.
        ; 1 if "Yes" => Create new player.

        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

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
        mov r10, [rel lcl_interactor_ptr]
        mov r10, [r10 + interactor.file_manager_ptr]
        mov r10, [r10 + file_manager.getter_vtable_ptr]
        call [r10 + FILE_MANAGER_GETTER_NUM_OF_ENTRIES_OFFSET]
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
        ; Set up stack frame.
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stsack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Prepare interactor pointer in RBX and R10.
        mov rbx, [rel lcl_interactor_ptr]
        mov r10, rbx

        ; Prepare designer pointer in RBX.
        mov rbx, [rbx + interactor.designer_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32
    
    .destroy_old_player:
        mov r10, [r10 + interactor.game_ptr]
        mov r10, [r10 + game.options_ptr]
        mov r10, [r10 + options.player_ptr]
        mov r10, [r10 + player.methods_vtable_ptr]
        call [r10 + PLAYER_METHODS_DESTRUCTOR_OFFSET]

    .clear_screen:
        mov r10, [rbx + designer.console_manager_ptr]
        mov r10, [r10 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .change_dialogue:
        lea rcx, [rel player_change_table]
        mov rdx, player_change_table_size
        xor r8, r8
        mov r10, [rbx + designer.methods_vtable_ptr]
        call [r10 + DESIGNER_METHODS_TYPE_SEQUENCE_OFFSET]

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

        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_create_player_from_file:
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

        ; Prepare interactor pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]

        ; Prepare designer pointer in R12.
        mov r12, [rbx + interactor.designer_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        mov r10, [r12 + designer.console_manager_ptr]
        mov r10, [r10 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .write_headline:
        lea rcx, [rel file_player_headline]
        mov rdx, file_player_headline_length
        mov r10, [r12 + designer.methods_vtable_ptr]
        call [r10 + DESIGNER_METHODS_WRITE_HEADLINE_OFFSET]

    .show_leaderboard:
        call _show_leaderboard

    .check_for_entries:
        mov r10, [rbx + interactor.file_manager_ptr]
        mov r10, [r10 + file_manager.getter_vtable_ptr]
        call [r10 + FILE_MANAGER_GETTER_NUM_OF_ENTRIES_OFFSET]
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
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_create_new_player:
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

        ; Prepare interactor pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]

        ; Prepare designer pointer in R12.
        mov r12, [rbx + interactor.designer_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        mov r10, [r12 + designer.console_manager_ptr]
        mov r10, [r10 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .get_name:
        lea rcx, [rel new_player_table]
        mov rdx, new_player_table_size
        mov r8, 0
        mov r10, [r12 + designer.methods_vtable_ptr]
        call [r10 + DESIGNER_METHODS_TYPE_SEQUENCE_OFFSET]

        call _get_player_name

    .create_player:
        lea rcx, [rel lcl_i_player_name]
        xor rdx, rdx
        call player_new

        ; * First local variable: Player pointer.
        mov r12, rax

    .add_player_to_file:
        lea rcx, [rel lcl_i_player_name]
        xor rdx, rdx
        mov r10, [rbx + interactor.file_manager_ptr]
        mov r10, [r10 + file_manager.methods_vtable_ptr]
        call [r10 + FILE_MANAGER_METHODS_ADD_RECORD_OFFSET]

    .complete:
        ; Return created player in RAX.
        mov rax, r12

        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

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
        mov r10, [rel lcl_interactor_ptr]
        mov r10, [r10 + interactor.file_manager_ptr]
        mov r10, [r10 + file_manager.methods_vtable_ptr]
        call [r10 + FILE_MANAGER_METHODS_UPDATE_TABLE_OFFSET]

    .write_leaderboard:
        mov rcx, rax
        mov r10, [rel lcl_interactor_ptr]
        mov r10, [r10 + interactor.designer_ptr]
        mov r10, [r10 + designer.methods_vtable_ptr]
        call [r10 + DESIGNER_METHODS_WRITE_TABLE_OFFSET]

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_get_player_index:
    ; * Expect num of entries in RCX.
    .set_up:
        ; Set up stack frame.
        ; * 24 bytes local variables.
        ; * 8 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13

        ; Save num of entries in RBX.
        mov rbx, rcx

        ; Save console_manager.methods_table into R13.
        mov r13, [rel lcl_interactor_ptr]
        mov r13, [r13 + interactor.designer_ptr]
        mov r13, [r13 + designer.console_manager_ptr]
        mov r13, [r13 + console_manager.methods_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .get_digits:
        call helper_get_digits_of_number
        mov r12, rax

    .get_index_loop:
        mov rcx, r12

        call [r13 + CONSOLE_MANAGER_METHODS_RECIEVE_NUMBER_OFFSET]

        cmp rax, rbx
        ja .get_index_loop
        cmp rax, 1
        jb .get_index_loop

    .complete:
        ; Decrement RAX, so it is the actual index and return it.
        dec rax

        ; Restore non-volatile regs.
        mov r13, [rbp - 24]
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
        mov r10, [rel lcl_interactor_ptr]
        mov r10, [r10 + interactor.file_manager_ptr]
        mov r10, [r10 + file_manager.getter_vtable_ptr]
        call [r10 + FILE_MANAGER_GETTER_RECORD_BY_INDEX_OFFSET]

    .parse_highscore:
        lea rcx, [rel player_from_file_struc + 16]
        mov rdx, 4
        call helper_parse_saved_to_int

    .create_player:
        lea rcx, [rel player_from_file_struc]
        mov rdx, rax
        call player_new

    .complete:
        ; Return created player in RAX.

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_get_player_name:
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

        ; Prepare interactor pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]

        ; Prepare file_manager.getter_table in R12.
        mov r12, [rbx + interactor.file_manager_ptr]
        mov r12, [r12 + file_manager.getter_vtable_ptr]

        ; Prepare console_manager.methods_vtable in RBX.
        mov rbx, [rbx + interactor.designer_ptr]
        mov rbx, [rbx + designer.console_manager_ptr]
        mov rbx, [rbx + console_manager.methods_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .name_loop:
        lea rcx, [rel lcl_i_player_name]
        mov rdx, PLAYER_NAME_LENGTH - 1
        call [rbx + CONSOLE_MANAGER_METHODS_RECIEVE_LETTERS_OFFSET]

        ; Zero out the memory space which is not used.
        call _clear_player_name

        ; It is not valid if name already exists.
        lea rcx, [rel lcl_i_player_name]
        call [r12 + FILE_MANAGER_GETTER_NAME_OFFSET]
        cmp rax, -1
        jne .name_loop

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_get_level:
    ; * Expect pointer to string table in RCX.
    ; * Expect size of table in RDX.
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

        ; Save params into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], rdx

        ; Prepare designer pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.designer_ptr]

        ; Prepare console_manager.methods_table in R12.
        mov r12, [rbx + designer.console_manager_ptr]
        mov r12, [r12 + console_manager.methods_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        call [r12 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .level_creation_dialogue:
        mov rcx, [rbp + 16]
        mov rdx, [rbp + 24]
        xor r8, r8
        mov r10, [rbx + designer.methods_vtable_ptr]
        call [r10 + DESIGNER_METHODS_TYPE_SEQUENCE_OFFSET]

    .level_loop:              
        mov rcx, 1
        call [r12 + CONSOLE_MANAGER_METHODS_RECIEVE_NUMBER_OFFSET]
        cmp rax, 9
        ja .level_loop
        cmp rax, 1
        jb .level_loop

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_show_options_table:
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

        ; Prepare designer pointer in RBX.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.designer_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .clear_screen:
        mov r10, [rbx + designer.console_manager_ptr]
        mov r10, [r10 + console_manager.methods_vtable_ptr]
        call [r10 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

    .show_options:
        lea rcx, [rel after_game_table]
        mov rdx, after_game_table_size
        xor r8, r8
        mov r10, [rbx + designer.methods_vtable_ptr]
        call [r10 + DESIGNER_METHODS_TYPE_SEQUENCE_OFFSET]

    .complete:
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_handle_options:
    ; * Expect pointer to old options in RCX.
    .set_up:
        ; Set up stack frame.
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If interactor is not created, let the user know.
        cmp qword [rel lcl_interactor_ptr], 0
        je _i_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14

        ; Make RBX point to old options object.
        mov rbx, rcx

        ; Prepare designer pointer in R13.
        mov r13, [rel lcl_interactor_ptr]
        mov r13, [r13 + interactor.designer_ptr]

        ; Prepare console_manager.methods_table in R14.
        mov r14, [r13 + designer.console_manager_ptr]
        mov r14, [r14 + console_manager.methods_vtable_ptr]

        ; Prepare designer.methods_vtable in R13.
        mov r13, [r13 + designer.methods_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .options_loop:
        ; Clearing the screen.
        call [r14 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

        ; Showing the options table.
        call _show_options_table

        ; Get one byte numeral input.
        mov rcx, 1
        call [r14 + CONSOLE_MANAGER_METHODS_RECIEVE_NUMBER_OFFSET]

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
        call [r10 + OPTIONS_METHODS_DESTRUCTOR_OFFSET]

        ; Returning the new options object in RAX.
        mov rax, r12
        jmp .complete

    .handle_change_level:
        ; Let the user choose the new level.
        lea rcx, [rel level_change_table]
        mov rdx, level_change_table_size
        call _get_level

        ; Creating new options, based on the new level.
        mov rcx, [rbx + options.player_ptr]
        mov rdx, rax
        call options_new
        mov r12, rax

        ; Destroying the old options object.
        mov rcx, rbx
        mov r10, [rcx + options.methods_vtable_ptr]
        call [r10 + OPTIONS_METHODS_DESTRUCTOR_OFFSET]

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
        call [r10 + OPTIONS_METHODS_DESTRUCTOR_OFFSET]

        ; Return new options object in RAX.
        mov rax, r12
        jmp .complete

    .handle_show_leaderboard:
        ; Clear screen.
        call [r14 + CONSOLE_MANAGER_METHODS_CLEAR_ALL_OFFSET]

        ; Write headline of leaderboard.
        lea rcx, [rel leaderboard_headline]
        mov rdx, leaderboard_headline_length
        call [r13 + DESIGNER_METHODS_WRITE_HEADLINE_OFFSET]

        ; Showing the leaderboard.
        call _show_leaderboard

        ; Waiting for a "Enter" of the user.
        lea rcx, [rbp - 24]
        mov rdx, 1
        call [r14 + CONSOLE_MANAGER_METHODS_RECIEVE_LETTERS_OFFSET]

        ; Go back to after game screen.
        jmp .options_loop

    .handle_exit:
        ; Exit the game.
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

_get_yes_no:
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

        ; Prepare console_manager.methods_table in RBX.
        mov rbx, [rel lcl_interactor_ptr]
        mov rbx, [rbx + interactor.designer_ptr]
        mov rbx, [rbx + designer.console_manager_ptr]
        mov rbx, [rbx + console_manager.methods_vtable_ptr]

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .yes_no_loop:
        ; * First local variable: Pointer to recieve byte at.
        lea rcx, [rbp - 16]
        mov rdx, 1
        call [rbx + CONSOLE_MANAGER_METHODS_RECIEVE_LETTERS_OFFSET]

        ; Check if input is a "Y" or a "N"
        mov al, [rbp - 16]
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
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

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
        lea rdx, [rel lcl_i_player_name]

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