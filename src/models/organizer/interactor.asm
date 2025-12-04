; Data:
%include "./include/data/interactor_strings/interactor_strings.inc"

; Strucs:
%include "./include/strucs/organizer/interactor_struc.inc"
%include "./include/strucs/organizer/file_manager_struc.inc"
%include "./include/strucs/organizer/table/table_struc.inc"
%include "./include/strucs/game/game_struc.inc"
%include "./include/strucs/game/player_struc.inc"
%include "./include/strucs/game/options_struc.inc"

global interactor_new, interactor_setup, interactor_create_game, interactor_start_game, interactor_destroy, interactor_replay_game

section .rodata
    ;;;;;; CONSTANTS ;;;;;;
    DEFAULT_BOARD_HEIGHT equ 10             ; 0 indexed - so: 11
    DEFAULT_BOARD_WIDTH equ 19              ; 0 indexed - so: 20
    PLAYER_NAME_LENGTH equ 16               ; 15 signs, 0 terminated.

    ;;;;;; DEBUGGING ;;;;;;
    recieved_char db "%c", 0
    player_name db "%s", 13, 10, 0
    return_value db "%d", 0

    ;;;;;; FORMATS ;;;;;;;
    char_format db "%c", 0
    name_string_format db "%15s", 0
    digit_format db "%d", 0

section .bss
    INTERACTOR_PTR resq 1
    INTERACTOR_PLAYER_NAME resb PLAYER_NAME_LENGTH
    INTERACTOR_YES_NO resq 1

    player_from_file_struc:
        .name resb PLAYER_NAME_LENGTH
        .highscore resd 1
    player_from_file_struc_end:

section .text
    extern malloc, free
    extern Sleep

    extern console_manager_get_literal_input, console_manager_get_numeral_input, console_manager_clear_all, console_manager_set_console_cursor_info
    extern designer_new, designer_start_screen, designer_type_sequence, designer_write_table, designer_write_headline
    extern game_new, game_start, game_reset
    extern file_manager_new, file_manager_add_leaderboard_record, file_manager_get_record_by_index, file_manager_get_num_of_entries, file_manager_get_name, file_manager_get_total_bytes, file_manager_create_table_from_file, file_manager_update_table
    extern player_new, player_destroy
    extern helper_get_digits_of_number, helper_get_digits_in_string, helper_parse_saved_to_int
    extern options_new, options_destroy

interactor_new:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    cmp qword [rel INTERACTOR_PTR], 0
    jne .complete

    ; Save non-volatile regs.
    mov [rbp - 8], rbx

    mov rcx, interactor_size
    call malloc
    mov [rel INTERACTOR_PTR], rax

    call designer_new
    mov rbx, [rel INTERACTOR_PTR]
    mov [rbx + interactor.designer_ptr], rax

    call file_manager_new
    mov [rbx + interactor.file_manager_ptr], rax

    call file_manager_create_table_from_file
    mov [rbx + interactor.table_ptr], rax

.complete:
    ; Restore non-volatile regs.
    mov rbx, [rbp - 8]

    mov rax, [rel INTERACTOR_PTR]
    mov rsp, rbp
    pop rbp
    ret

interactor_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel INTERACTOR_PTR]
    call free
    mov qword [rel INTERACTOR_PTR], 0

    mov rsp, rbp
    pop rbp
    ret

interactor_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call designer_start_screen
    mov rcx, 1000
    call Sleep
    call console_manager_clear_all
    mov ecx, 1
    call console_manager_set_console_cursor_info
    call _introduction

    mov rsp, rbp
    pop rbp
    ret

interactor_create_game:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    call _create_player
    mov [rbp - 8], rax

    call _create_level
    mov rdx, rax
    mov rcx, [rbp - 8]
    call options_new
    mov [rbp - 8], rax

    xor rcx, rcx
    mov cx, DEFAULT_BOARD_WIDTH                   ; Moving width into CX  (So: ECX = 0, width)
    shl rcx, 16                                   ; Shifting rcx 16 bits left (So : ECX = width, 0)
    mov cx, DEFAULT_BOARD_HEIGHT                  ; Moving height into CX (So: ECX = width, height)

    mov rdx, [rbp - 8]
    mov r8, [rel INTERACTOR_PTR]

    call game_new

    mov rcx, [rel INTERACTOR_PTR]
    mov [rcx + interactor.game_ptr], rax

    mov rsp, rbp
    pop rbp
    ret

interactor_start_game:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    xor ecx, ecx
    call console_manager_set_console_cursor_info
    call game_start

    mov rsp, rbp
    pop rbp
    ret

interactor_replay_game:
    push rbp
    mov rbp, rsp
    sub rsp, 40

.loop:
    mov ecx, 1
    call console_manager_set_console_cursor_info
    sub rsp, 32
    mov rcx, [rel INTERACTOR_PTR]
    mov rcx, [rcx + interactor.game_ptr]
    mov rcx, [rcx + game.options_ptr]
    call _handle_options
    test rax, rax
    jz .complete
    mov [rbp - 8], rax
    xor ecx, ecx
    call console_manager_set_console_cursor_info
    mov rcx, [rbp - 8]
    call game_reset
    jmp .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret


;;;;;; PRIVATE METHODS ;;;;;;
_introduction:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Clear console before writing new sequence.
    call console_manager_clear_all

    lea rcx, [rel intro_table]
    mov rdx, intro_table_size
    mov r8, 0
    call designer_type_sequence

.complete:
    mov rsp, rbp
    pop rbp
    ret

_create_player:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call file_manager_get_num_of_entries
    test rax, rax
    jz .create_new_player
    
    call _get_yes_no
    test rax, rax
    jnz .create_new_player

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
    push rbp
    mov rbp, rsp
    sub rsp, 48

    call player_destroy

    call console_manager_clear_all

    lea rcx, [rel player_change_table]
    mov rdx, player_change_table_size
    xor r8, r8
    call designer_type_sequence

.loop:
    lea rcx, [rbp - 8]
    mov rdx, 1
    call console_manager_get_literal_input
    mov al, [rbp - 8]
    and al, 0xDF
    cmp al, "N"
    je .change_new_player
    cmp al, "E"
    je .change_existing_player
    jmp .loop

.change_existing_player:
    call _create_player_from_file
    jmp .complete

.change_new_player:
    call _create_new_player

.complete:
    mov rsp, rbp
    pop rbp
    ret

_create_player_from_file:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    call console_manager_clear_all

    lea rcx, [rel file_player_headline]
    mov rdx, file_player_headline_length
    call designer_write_headline

    call _show_leaderboard

    call file_manager_get_num_of_entries
    mov [rbp - 8], rax

.loop:
    mov rcx, [rbp - 8]
    call _get_player_index
    cmp rax, [rbp - 8]
    ja .loop
    cmp rax, 0
    jb .loop

    dec rax
    mov rcx, rax
    call _create_player_from_index

    mov rsp, rbp
    pop rbp
    ret

_create_new_player:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Clear console before writing new sequence.
    call console_manager_clear_all

    lea rcx, [rel new_player_table]
    mov rdx, new_player_table_size
    mov r8, 0
    call designer_type_sequence

    call _create_player_name

    lea rcx, [rel INTERACTOR_PLAYER_NAME]
    xor rdx, rdx
    call player_new
    mov [rbp - 8], rax

    lea rcx, [rel INTERACTOR_PLAYER_NAME]
    xor rdx, rdx
    call file_manager_add_leaderboard_record

    mov rax, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

_show_leaderboard:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel INTERACTOR_PTR]
    mov rcx, [rcx + interactor.table_ptr]
    call file_manager_update_table

    mov rcx, rax
    call designer_write_table

    mov rsp, rbp
    pop rbp
    ret

_get_player_index:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; * Expect num of entries in RCX.
    mov [rbp - 8], rcx

    call helper_get_digits_of_number
    mov [rbp - 16], rax

.loop:
    mov rcx, [rbp - 16]
    call console_manager_get_numeral_input
    cmp rax, [rbp - 8]
    ja .loop
    cmp rax, 1
    jb .loop
    mov [rbp - 24], rax

.complete:
    mov rax, [rbp - 24]
    mov rsp, rbp
    pop rbp
    ret

_create_player_from_index:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; * Expectindex of player in RCX.
    mov rdx, rcx
    lea rcx, [rel player_from_file_struc]
    call file_manager_get_record_by_index

    lea rcx, [rel player_from_file_struc + 16]
    mov rdx, 4
    call helper_parse_saved_to_int

    lea rcx, [rel player_from_file_struc]
    mov rdx, rax
    call player_new

    mov rsp, rbp
    pop rbp
    ret

_create_player_name:
    push rbp
    mov rbp, rsp
    sub rsp, 40

.loop:
    lea rcx, [rel INTERACTOR_PLAYER_NAME]
    mov rdx, 15
    call console_manager_get_literal_input
    call _clear_player_name

    lea rcx, [rel INTERACTOR_PLAYER_NAME]
    call file_manager_get_name
    cmp rax, -1
    jne .loop

    mov rsp, rbp
    pop rbp
    ret

_create_level:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Clear console before writing new sequence.
    call console_manager_clear_all

    lea rcx, [rel level_creation_table]
    mov rdx, level_creation_table_size
    mov r8, 0
    call designer_type_sequence

.loop:              
    mov rcx, 1
    call console_manager_get_numeral_input
    cmp rax, 9
    ja .loop
    cmp rax, 1
    jb .loop

    mov rsp, rbp
    pop rbp
    ret

_change_level:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call console_manager_clear_all

    lea rcx, [rel level_change_table]
    mov rdx, level_change_table_size
    xor r8, r8
    call designer_type_sequence

.loop:
    mov rcx, 1
    call console_manager_get_numeral_input
    cmp rax, 9
    ja .loop
    cmp rax, 1
    jb .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret

_show_options_table:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Clear console before writing new sequence.
    call console_manager_clear_all

    lea rcx, [rel after_game_table]
    mov rdx, after_game_table_size
    xor r8, r8
    call designer_type_sequence

    mov rsp, rbp
    pop rbp
    ret

_handle_options:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Save non-volatile regs.
    mov [rbp - 8], rbx

    ; * Expectpointer to old options in RCX.
    mov [rbp - 16], rcx

    mov rbx, rcx
.loop:
    call console_manager_clear_all

    call _show_options_table

    mov rcx, 1
    call console_manager_get_numeral_input
    cmp rax, 6
    ja .loop

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
    mov rax, [rbp - 16]
    jmp .complete

.handle_change_player:
    call _change_player
    mov rcx, rax
    mov edx, [rbx + options.lvl]
    call options_new
    mov [rbp - 24], rax

    mov rcx, [rbp - 16]
    call options_destroy

    mov rax, [rbp - 24]
    jmp .complete

.handle_change_level:
    call _change_level
    mov rcx, [rbx + options.player_ptr]
    mov rdx, rax
    call options_new
    mov [rbp - 24], rax

    mov rcx, [rbp - 16]
    call options_destroy

    mov rax, [rbp - 24]
    jmp .complete

.handle_change_both:
    call _change_player
    mov [rbp - 24], rax

    call _change_level
    mov rdx, rax

    mov rcx, [rbp - 24]
    mov rdx, rax
    call options_new
    mov [rbp - 24], rax

    mov rcx, [rbp - 16]
    call options_destroy

    mov rax, [rbp - 24]
    jmp .complete

.handle_show_leaderboard:
    call console_manager_clear_all

    lea rcx, [rel leaderboard_headline]
    mov rdx, leaderboard_headline_length
    call designer_write_headline

    call _show_leaderboard

    lea rcx, [rbp - 32]
    mov rdx, 1
    call console_manager_get_literal_input

    jmp .loop

.handle_exit:
    xor rax, rax

.complete:
    ; Restore non-volatile regs.
    mov rbx, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret

_get_yes_no:
    push rbp
    mov rbp, rsp
    sub rsp, 40

.loop:
    lea rcx, [rel INTERACTOR_YES_NO]
    mov rdx, 1
    call console_manager_get_literal_input
.afterwards:
    mov al, [rel INTERACTOR_YES_NO]
    and al, 0xDF
    cmp al, "Y"
    je .yes
    cmp al, "N"
    je .no
    jmp .loop

.yes:
    mov rax, 1
    jmp .complete
.no:
    xor rax, rax

.complete:
    mov rsp, rbp
    pop rbp
    ret

_clear_player_name:
    push rbp
    mov rbp, rsp

    mov rcx, PLAYER_NAME_LENGTH
    lea rdx, [rel INTERACTOR_PLAYER_NAME]
    mov byte [rdx + rcx], 0
.loop:
    cmp byte [rdx + rcx], 10
    je .clear_cr
    cmp byte [rdx + rcx], 13
    je .clear_lf
    loop .loop
    jmp .complete

.clear_cr:
    dec rcx
    mov word [rdx + rcx], 0
    jmp .complete

.clear_lf:
    mov byte [rdx + rcx], 0

.complete:
    mov rsp, rbp
    pop rbp
    ret