%include "../include/organizer/interactor_struc.inc"
%include "../include/organizer/file_manager_struc.inc"

global interactor_new, interactor_setup, interactor_create_game, interactor_start_game, interactor_after_game_dialogue, interactor_destroy

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    recieved_char db "%c", 0
    player_name db "%s", 13, 10, 0

    ;;;;;; FORMATS ;;;;;;;
    char_format db "%c", 0
    string_format db "%s", 0
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
        .string3 db 0
    new_player_end:

    new_player_table:
        dq new_player.string1, (new_player.string2 - new_player.string1)
        dq new_player.string2, (new_player.string3 - new_player.string2)
        dq new_player.string3, (new_player_end - new_player.string3)
    new_player_table_end:
    new_player_table_size equ (new_player_table_end - new_player_table) /16

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
    INTERACTOR_PLAYER_NAME_PTR resq 1
    INTERACTOR_YES_NO_PTR resq 1
    INTERACTOR_LEVEL_PTR resq 1

section .text
    extern malloc, free
    extern printf
    extern Sleep

    extern console_manager_scan
    extern designer_new, designer_start_screen, designer_clear, designer_type_sequence
    extern game_new, game_start, game_setup
    extern file_manager_new
    extern player_new

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
    sub rsp, 40

    call _create_player
    mov [rbp - 8], rax

    call _create_level

    xor rcx, rcx
    mov cx, 20                  ; Moving width into CX  (So: ECX = 0, width)
    shl rcx, 16                 ; Shifting rcx 16 bits left (So : ECX = width, 0)
    mov cx, 11                  ; Moving height into CX (So: ECX = width, height)

    ; Have to create dialogue to get level.
    mov rdx, [rel INTERACTOR_LEVEL_PTR]

    mov r8, [rbp - 8]
    mov r9, [rel INTERACTOR_PTR]
    call game_new

    mov rsp, rbp
    pop rbp
    ret

interactor_start_game:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call game_setup
    call game_start

    mov rsp, rbp
    pop rbp
    ret

interactor_after_game_dialogue:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel after_game_table]
    mov rdx, after_game_table_size
    call designer_type_sequence

    call _get_yes_no

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

.choose_former_player:
    ; This option has to be implemented later (save player in a file and let player choose one former player).
    mov rax, 0
    jmp .complete
.create_new_player:
    lea rcx, [rel new_player_table]
    mov rdx, new_player_table_size
    call designer_type_sequence

    call _get_new_player

.complete:
    mov rsp, rbp
    pop rbp
    ret

_create_level:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel level_creation_table]
    mov rdx, level_creation_table_size
    call designer_type_sequence

.loop:
    lea rcx, [rel digit_format]                
    lea rdx, [rel INTERACTOR_LEVEL_PTR]
    call console_manager_scan
    cmp qword [rel INTERACTOR_LEVEL_PTR], 1
    jb .loop
    cmp qword [rel INTERACTOR_LEVEL_PTR], 9
    ja .loop

    mov rsp, rbp
    pop rbp
    ret

_get_new_player:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _get_player_name

    lea rcx, [rel INTERACTOR_PLAYER_NAME_PTR]
    call player_new

    mov rsp, rbp
    pop rbp
    ret

_get_player_name:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel string_format]                ; Make 8-Byte names possible.
    lea rdx, [rel INTERACTOR_PLAYER_NAME_PTR]
    call console_manager_scan

    mov rsp, rbp
    pop rbp
    ret

_get_yes_no:
    push rbp
    mov rbp, rsp
    sub rsp, 40

.loop:
    lea rcx, [rel char_format]
    lea rdx, [rel INTERACTOR_YES_NO_PTR]
    call console_manager_scan
    mov al, [rel INTERACTOR_YES_NO_PTR]
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
    mov rax, 0

.complete:
    mov rsp, rbp
    pop rbp
    ret
