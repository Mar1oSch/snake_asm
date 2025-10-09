%include "../include/organizer/file_manager_struc.inc"

global file_manager_new, file_manager_add_leaderboard_record, file_manager_destroy, file_manager_get_record

section .rodata
    leaderboard_file_name db "leaderboard.bin", 0
    ;;;;;; Debugging ;;;;;;
    format db "%16s", 0

    ;;;;;; BIN Header ;;;;;;
header_template:
    magic db "LDB1"
    version dw 1
    header_size dw 16
    record_size dw 20
    reserved dw 0
    record_count dd 0
header_template_end:
    HEADER_SIZE equ header_template_end - header_template
    FILE_BEGIN   equ 0


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
    FILE_MANAGER_HEADER resq 2

section .text
    extern malloc, free
    extern CreateFileA, CloseHandle
    extern ReadFile, WriteFile
    extern GetFileSizeEx, SetFilePointerEx
    extern printf

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

file_manager_get_record:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect buffer to player_struc in RCX.
    ; Expect index of player in file in RDX.
    mov [rbp - 8], rcx

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    mov rdx, HEADER_SIZE
    xor r8, r8
    mov r9, FILE_BEGIN
    call SetFilePointerEx

    mov rcx, [rbp - 8]
    call _read

    mov rsp, rbp
    pop rbp
    ret

file_manager_add_leaderboard_record:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Expect pointer to player_name in RCX.
    ; Expect highscore in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx

    call _ensure_header_initialized

    mov rcx, [rbp - 8]
    mov rdx, 16
    call _write

    lea rcx, [rbp - 16]
    mov rdx, 4
    call _write

    mov rsp, rbp
    pop rbp
    ret



;;;;;; PRIVATE FUNCTIONS ;;;;;;
_write:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to string to write in RCX.
    ; Expect amount of bytes to write in RDX.
    mov r8, rdx
    mov rdx, rcx

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    xor r9, r9
    mov qword [rsp + 32], 0
    call WriteFile

    mov rsp, rbp
    pop rbp
    ret

_read:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to string to load read bytes into in RCX.
    mov rdx, rcx

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    mov r8d, [rel record_size]
    xor r9, r9
    mov qword [rsp + 32], 0
    call ReadFile

    mov rsp, rbp
    pop rbp
    ret

_ensure_header_initialized:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    ; Save non volatile registers.
    mov [rbp - 8], r15

    mov r15, [rel FILE_MANAGER_PTR]
    mov r15, [r15 + file_manager.file_handle]

    mov rcx, r15
    lea rdx, [rel FILE_SIZE_LARGE_INT]
    call GetFileSizeEx
    test eax, eax
    jz .init_header

    mov rax, [rel FILE_SIZE_LARGE_INT]
    cmp rax, HEADER_SIZE
    jb .init_header

    mov rcx, r15
    xor rdx, rdx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call SetFilePointerEx

    mov rcx, r15
    lea rdx, [rel FILE_MANAGER_HEADER]
    mov r8d, HEADER_SIZE
    lea r9, [rbp - 16]
    mov qword [rsp + 32], 0
    call ReadFile
    test eax, eax
    jz .init_header

    mov eax, [rel FILE_MANAGER_HEADER]
    cmp eax, [rel magic]
    jne .init_header

    movzx eax, word [rel FILE_MANAGER_HEADER + 8]
    cmp ax, [rel record_size]
    jne .init_header

    xor rax, rax
    jmp .complete

.init_header:
    mov rcx, r15
    xor rdx, rdx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call SetFilePointerEx

    mov rcx, r15
    lea rdx, [rel header_template]
    mov r8d, HEADER_SIZE
    xor r9, r9
    mov qword [rsp + 32], 0
    call WriteFile

    xor rax, rax

.complete:
    mov rsp, rbp
    pop rbp
    ret