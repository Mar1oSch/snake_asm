%include "../include/organizer/file_manager_struc.inc"

global file_manager_new, file_manager_add_leaderboard_record, file_manager_destroy

section .rodata
    leaderboard_file_name db "leaderboard.bin", 0

    ;;;;;; BIN Header ;;;;;;
header_template:
    magic db "LDB1"
    version dw 1
    header_size dw 16
    record_size dw 20
    reserved dw 0
    record_count dd 0
header_template_end:

    FILE_BEGIN   equ 0
    HEADER_OFFSET equ 16


    ;;;;;; CREATE FILE CONSTANTS ;;;;;;
    GENERIC_READ equ 0x80000000
    FILE_APPEND_DATA equ 0x0004

    FILE_SHARE_WRITE equ 0x00000002
    FILE_SHARE_READ equ 0x00000001

    OPEN_ALWAYS equ 4

    FILE_ATTRIBUTE_NORMAL equ 0x80

section .bss
    FILE_MANAGER_PTR resq 1
    FILE_SIZE_LARGE_INT resq 1

section .text
    extern malloc, free
    extern CreateFileA, CloseHandle
    extern ReadFile, WriteFile
    extern GetFileSizeEx, SetFilePointerEx

file_manager_new:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    cmp qword [rel FILE_MANAGER_PTR], 0
    jne .complete

    mov rcx, file_manager_size
    call malloc
    mov [rel FILE_MANAGER_PTR], rax

    lea rcx, [rel leaderboard_file_name]                ; lpFileName
    mov rdx, GENERIC_READ | FILE_APPEND_DATA            ; dwDesiredAccess
    mov r8, FILE_SHARE_READ | FILE_SHARE_WRITE          ; dwShareMode
    mov r9, 0                                           ; lpSecurityAttributes (optional)
    mov dword [rsp + 32], OPEN_ALWAYS                   ; dwCreationDisposition
    mov dword [rsp + 40], FILE_ATTRIBUTE_NORMAL         ; dwFlagsAndAttributes
    mov dword [rsp + 48], 0                             ; hTemplateFile (optional)
    call CreateFileA
    mov rcx, [rel FILE_MANAGER_PTR]
    mov [rcx + file_manager.file_handle], rax

.complete:
    mov rax, [rel FILE_MANAGER_PTR]
    mov rsp, rbp
    pop rbp
    ret

file_manager_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel FILE_MANAGER_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

file_manager_add_leaderboard_record:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect player_name_ptr in RCX.
    ; Expect length of player name in RDX.
    ; Expect highscore of player in R8D.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx
    mov [rbp - 24], r8d

    call _write

    ; lea rcx, [rel seperator]
    ; mov rdx, 1
    ; call _write

    ; lea rcx, [rbp - 24]
    ; mov rdx, 4
    ; call _write

    ; lea rcx, [rel closer]
    ; mov rdx, 3
    ; call _write

    mov rsp, rbp
    pop rbp
    ret



;;;;;; PRIVATE FUNCTIONS ;;;;;;
_write:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect pointer to string to write in RCX.
    ; Expect length of string in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    mov rdx, [rbp - 8]
    mov r8d, [rbp - 16]
    xor r9, r9
    mov qword [rsp + 32], 0
    call WriteFile

    mov rsp, rbp
    pop rbp
    ret

; _ensure_header_initialized:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 40

;     ; Save non volatile registers.
;     mov [rbp - 8], r15

;     mov r15, [rel FILE_MANAGER_PTR]
;     mov r15, [r15 + file_manager.file_handle]

;     mov rcx, r15
;     lea rdx, [rel FILE_SIZE_LARGE_INT]
;     call GetFileSizeEx

;     mov rcx, [rel header_size]
;     cmp qword [rel FILE_SIZE_LARGE_INT], rcx
;     jb .init_header

;     mov rcx, r15
;     mov rdx, 

