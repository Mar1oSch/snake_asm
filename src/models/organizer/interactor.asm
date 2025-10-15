%include "../include/organizer/interactor_struc.inc"
%include "../include/organizer/file_manager_struc.inc"
%include "../include/game/game_struc.inc"
%include "../include/game/player_struc.inc"

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

    ;;;;;; INTRODUCTION ;;;;;;
    introduction:
        .string1 db "Hello, fellow friend! Welcome to your snake adventure."    
        .string2 db "Is this the first time you are entering this dangerous territory?"
        .string3 db "[Y]es / [N]o"
        .string4 db 0
    introduction_end:

    intro_table:
        dq introduction.string1, (introduction.string2 - introduction.string1)
        dq introduction.string2, (introduction.string3 - introduction.string2)
        dq introduction.string3, (introduction.string4 - introduction.string3)
        dq introduction.string4, (introduction_end - introduction.string4)
    intro_table_end:
    intro_table_size equ (intro_table_end - intro_table) /16

    ;;;;;; PLAYER CREATION ;;;;;;
    new_player:
        .string1 db "A Very well welcome from my side."
        .string2 db "What is your name, adventurer?"
        .string3 db "(Max 15 signs)"
        .string4 db 0
    new_player_end:

    new_player_table:
        dq new_player.string1, (new_player.string2 - new_player.string1)
        dq new_player.string2, (new_player.string3 - new_player.string2)
        dq new_player.string3, (new_player.string4 - new_player.string3)
        dq new_player.string4, (new_player_end - new_player.string4)
    new_player_table_end:
    new_player_table_size equ (new_player_table_end - new_player_table) /16

    ;;;;;; FILE PLAYER CREATION ;;;;;;
    file_player:
        .string1 db "Welcome back then."
        .string2 db "What is your name?"
        .string3 db "(Max 15 signs)"
        .string4 db 0
    file_player_end:

    file_player_table:
        dq file_player.string1, (file_player.string2 - file_player.string1)
        dq file_player.string2, (file_player.string3 - file_player.string2)
        dq file_player.string3, (file_player.string4 - file_player.string3)
        dq file_player.string4, (file_player_end - file_player.string4)
    file_player_table_end:
    file_player_table_size equ (file_player_table_end - file_player_table) /16

    file_player_headline:
        db "Who are you?"
    file_player_headline_end:
    file_player_headline_length equ file_player_headline_end - file_player_headline

    ;;;;;; LEVEL CREATION ;;;;;;
    level_creation:
        .string1 db "Nice to meet you, brave person."
        .string2 db "How brave are you?"
        .string3 db "Which level do you want to play?"
        .string4 db "The ride is going to be harder on higher stages, but the rewards are rich."
        .string5 db 0
        .string6 db "[1] [2] [3] [4] [5] [6] [7] [8] [9]"
        .string7 db 0
    level_creation_end:

    level_creation_table:
        dq level_creation.string1, (level_creation.string2 - level_creation.string1)
        dq level_creation.string2, (level_creation.string3 - level_creation.string2)
        dq level_creation.string3, (level_creation.string4 - level_creation.string3)
        dq level_creation.string4, (level_creation.string5 - level_creation.string4)
        dq level_creation.string5, (level_creation.string6 - level_creation.string5)
        dq level_creation.string6, (level_creation.string7 - level_creation.string6)
        dq level_creation.string7, (level_creation_end - level_creation.string7)
    level_creation_table_end:
    level_creation_table_size equ (level_creation_table_end - level_creation_table) /16

    ;;;;;; GAME OVER ;;;;;;
    after_game:
        .string1 db "The ride was too bumpy for you I guess.."    
        .string2 db "But you played well! Do you want to play again?"
        .string3 db "[Y]es / [N]o"
        .string4 db 0
    after_game_end:

    after_game_table:
        dq after_game.string1, (after_game.string2 - after_game.string1)
        dq after_game.string2, (after_game.string3 - after_game.string2)
        dq after_game.string3, (after_game.string4 - after_game.string3)
        dq after_game.string4, (after_game_end - after_game.string4)
    after_game_table_end:
    after_game_table_size equ (after_game_table_end - after_game_table) /16

section .bss
    INTERACTOR_PTR resq 1
    INTERACTOR_PLAYER_NAME resb PLAYER_NAME_LENGTH
    INTERACTOR_YES_NO resq 1
    INTERACTOR_LVL resq 1

    player_from_file_struc:
        .name resb PLAYER_NAME_LENGTH
        .highscore resd 1
    player_from_file_struc_end:

section .text
    extern malloc, free
    extern printf
    extern Sleep

    extern console_manager_read, console_manager_clear
    extern designer_new, designer_start_screen, designer_clear, designer_type_sequence, designer_write_table, designer_write_headline
    extern game_new, game_start, game_reset
    extern file_manager_new, file_manager_add_leaderboard_record, file_manager_get_single_record, file_manager_get_all_records, file_manager_get_num_of_entries, file_manager_find_name, file_manager_get_record_length, file_manager_get_record_size_struc, file_manager_get_total_bytes
    extern player_new, get_player_name_length, get_player
    extern helper_get_digits_of_number, helper_get_digits_in_string, helper_is_input_just_numbers, helper_parse_string_to_number

interactor_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel INTERACTOR_PTR], 0
    jne .complete

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    mov rcx, interactor_size
    call malloc
    mov [rel INTERACTOR_PTR], rax

    call designer_new
    mov r15, [rel INTERACTOR_PTR]
    mov [r15 + interactor.designer_ptr], rax

    call file_manager_new
    mov [r15 + interactor.file_manager_ptr], rax

.complete:
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
    call designer_clear
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

    xor rcx, rcx
    mov cx, DEFAULT_BOARD_WIDTH                   ; Moving width into CX  (So: ECX = 0, width)
    shl rcx, 16                                   ; Shifting rcx 16 bits left (So : ECX = width, 0)
    mov cx, DEFAULT_BOARD_HEIGHT                  ; Moving height into CX (So: ECX = width, height)

    mov rdx, [rel INTERACTOR_LVL]

    mov r8, [rbp - 8]
    mov r9, [rel INTERACTOR_PTR]
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

    call game_start

    mov rsp, rbp
    pop rbp
    ret

interactor_replay_game:
    push rbp
    mov rbp, rsp
    sub rsp, 40

.loop:
    call _after_game_dialogue
    test rax, rax
    jz .complete
    call game_reset
    jmp .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret


;;;;;; PRIVATE FUNCTIONS ;;;;;;
_introduction:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel intro_table]
    mov rdx, intro_table_size
    mov r8, 0
    call designer_type_sequence

.complete:
    ; lea rcx, [rel recieved_char]
    ; mov rdx, rax
    ; call printf

    mov rsp, rbp
    pop rbp
    ret

_create_player:
    push rbp
    mov rbp, rsp
    sub rsp, 40

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

_create_player_from_file:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _create_leaderboard

    call _get_player_index
    dec rax
    mov rcx, rax
    call _create_player_from_index

    mov rsp, rbp
    pop rbp
    ret

_create_new_player:
    push rbp
    mov rbp, rsp
    sub rsp, 40

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

_create_leaderboard:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    call file_manager_get_total_bytes
    mov rcx, rax
    call malloc
    mov [rbp - 8], rax

    call file_manager_get_num_of_entries
    mov [rbp - 16], rax

    call file_manager_get_record_size_struc
    mov [rbp - 24], rax

    mov rcx, [rbp - 8]
    call file_manager_get_all_records

    call console_manager_clear

    lea rcx, [rel file_player_headline]
    mov rdx, file_player_headline_length
    call designer_write_headline

    mov rcx, [rbp - 8]
    mov rdx, 2
    mov r8, [rbp - 16]
    mov r9, [rbp - 24]
    call designer_write_table

    mov rcx, [rbp - 8]
    call free

    mov rsp, rbp
    pop rbp
    ret

_get_player_index:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    call file_manager_get_num_of_entries
    mov [rbp - 8], rax

    mov rcx, rax
    call helper_get_digits_of_number
    mov [rbp - 16], rax

    mov rcx, rax
    call malloc
    mov [rbp - 24], rax

.loop:
    mov rcx, [rbp - 24]
    mov rdx, [rbp - 16]
    call console_manager_read

    mov rcx, [rbp - 24]
    mov rdx, [rbp - 16]
    call helper_is_input_just_numbers
    test rax, rax
    jz .loop

    mov rcx, [rbp - 24]
    mov rdx, [rbp - 16]
    call helper_parse_string_to_number
    mov [rbp - 32], rax

.complete:
    mov rcx, [rbp - 24]
    call free

    mov rax, [rbp - 32]
    mov rsp, rbp
    pop rbp
    ret

_create_player_from_index:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect index of player in RCX.
    mov rdx, rcx
    lea rcx, [rel player_from_file_struc]
    call file_manager_get_single_record

    lea rcx, [rel player_from_file_struc]
    mov edx, [rel player_from_file_struc + 16]
    call player_new

    mov rsp, rbp
    pop rbp
    ret

_create_player_name:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel INTERACTOR_PLAYER_NAME]
    mov rdx, 15
    lea r8, [rbp - 8]
    call console_manager_read

    call _clear_player_name
    
    mov rsp, rbp
    pop rbp
    ret

_create_level:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel level_creation_table]
    mov rdx, level_creation_table_size
    mov r8, 0
    call designer_type_sequence

.loop:              
    lea rcx, [rel INTERACTOR_LVL]
    mov rdx, 1
    lea r8, [rbp - 8]
    call console_manager_read
    cmp qword [rel INTERACTOR_LVL], "1"
    jb .loop
    cmp qword [rel INTERACTOR_LVL], "9"
    ja .loop

    sub qword [rel INTERACTOR_LVL], 48                              ; ASCII-Convert: 48 = "0", 49 = "1", 50 = "2", ...
    mov rsp, rbp
    pop rbp
    ret

_after_game_dialogue:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel after_game_table]
    mov rdx, after_game_table_size
    mov r8, 0
    call designer_type_sequence

    call _get_yes_no

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
    lea r8, [rbp - 8]
    call console_manager_read
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