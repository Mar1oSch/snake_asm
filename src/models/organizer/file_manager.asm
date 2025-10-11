%include "../include/organizer/file_manager_struc.inc"

global file_manager_new, file_manager_add_leaderboard_record, file_manager_destroy, file_manager_get_record, file_manager_find_name, file_manager_update_highscore, file_manager_get_file_records_length

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

;;;;;; CREATE FILE CONSTANTS ;;;;;;
    GENERIC_READ equ 0x80000000
    GENERIC_WRITE equ 0x40000000
    FILE_APPEND_DATA equ 0x0004

    FILE_SHARE_WRITE equ 0x00000002
    FILE_SHARE_READ equ 0x00000001

    OPEN_ALWAYS equ 4

    FILE_ATTRIBUTE_NORMAL equ 0x80

;;;;;; FILE POINTER CONSTANTS ;;;;;;
    FILE_BEGIN   equ 0
    FILE_END equ 2

;;;;;; FILE CONSTANTS ;;;;;;
    FILE_NAME_OFFSET equ 0
    FILE_NAME_SIZE equ 16

    FILE_HIGHSCORE_OFFSET equ 16
    FILE_HIGHSCORE_SIZE equ 4

    FILE_RECORD_SIZE equ FILE_NAME_SIZE + FILE_HIGHSCORE_SIZE

section .bss
    FILE_MANAGER_PTR resq 1
    FILE_SIZE_LARGE_INT resq 1
    FILE_MANAGER_HEADER resq 2

    FILE_MANAGER_ACTIVE_RECORD resb FILE_RECORD_SIZE
    FILE_MANAGER_ACTIVE_NAME resb FILE_NAME_SIZE
    FILE_MANAGER_ACTIVE_FILE_POINTER resq 1
    FILE_MANAGER_BYTES_READ resd 1
    FILE_MANAGER_BYTES_WRITTEN resd 1

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
    mov rdx, GENERIC_READ | GENERIC_WRITE            ; dwDesiredAccess
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

    ; Expect pointer to player_name in RCX.
    ; Expect highscore in RDX.
    mov [rbp - 8], rcx
    mov [rbp - 16], rdx

    call _ensure_header_initialized

    call _set_pointer_end

    mov rcx, [rbp - 8]
    mov rdx, FILE_NAME_SIZE
    call _write

    lea rcx, [rbp - 16]
    mov rdx, FILE_HIGHSCORE_SIZE
    call _write

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

    mov rcx, rdx
    mov rdx, FILE_NAME_OFFSET
    call _set_pointer

    mov rcx, [rbp - 8]
    mov rdx, FILE_RECORD_SIZE
    call _read

    mov rsp, rbp
    pop rbp
    ret

; This function looks for a specified name (handed in by the register RCX) and returns its index in RAX if found.
; If it doesn't find that name, it returns -1 in RAX.
file_manager_find_name:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    ; Save non-volatile registers.
    mov [rbp - 8], rsi
    mov [rbp - 16], rdi
    mov [rbp - 24], r15

    ; Expect pointer to name in RCX.
    mov [rbp - 32], rcx

    xor r15, r15                ; Set index to zero.
.loop:
    lea rdi, [rel FILE_MANAGER_ACTIVE_NAME]
    mov rsi, [rbp - 32]
    mov rcx, rdi
    mov rdx, r15
    call _get_name
    cmp dword [rel FILE_MANAGER_BYTES_READ], 0
    je .not_equal
    .inner_loop:
        mov rcx, FILE_NAME_SIZE
        cld
        repe cmpsb
        je .equal
.loop_handle:
    inc r15
    jmp .loop

.equal:
    mov rax, r15
    jmp .complete

.not_equal:
    mov rax, -1

.complete:
    ; Restore non-volatile registers.
    mov r15, [rbp - 24]
    mov rdi, [rbp - 16]
    mov rsi, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret

file_manager_update_highscore:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect highscore in RCX.
    ; Expect player offset in RDX.
    mov [rbp - 8], rcx

    mov rcx, rdx
    mov rdx, FILE_HIGHSCORE_OFFSET
    call _set_pointer

    lea rcx, [rbp - 8]
    mov rdx, FILE_HIGHSCORE_SIZE
    call _write

    mov rsp, rbp
    pop rbp
    ret

file_manager_get_file_records_length:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    call _set_pointer_end
    mov r15, [rel FILE_MANAGER_ACTIVE_FILE_POINTER]

    call _set_pointer_start
    add qword [rel FILE_MANAGER_ACTIVE_FILE_POINTER], HEADER_SIZE
    sub r15, [rel FILE_MANAGER_ACTIVE_FILE_POINTER]

.complete:
    mov rax, r15

    ; Restore non-volatile regs.
    mov r15, [rbp - 8]

    mov rsp, rbp
    pop rbp
    ret



;;;;;; PRIVATE FUNCTIONS ;;;;;;
_set_pointer:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect index in RCX.
    ; Expect Offset in RDX.
    mov [rbp - 8], rdx

    ; Set FilePointer position:
    mov rdx, rcx                            ; 1.: Move index into RDX.
    imul rdx, FILE_RECORD_SIZE              ; 2.: Multiplicate index with the record size, to jump to destination record.
    add rdx, HEADER_SIZE                    ; 3.: Add the HEADER_SIZE to get to the right offset.
    add rdx, [rbp - 8]                      ; 4.: Add the Record_offset to get either to the name or highscore.

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    lea r8, [rel FILE_MANAGER_ACTIVE_FILE_POINTER]
    mov r9, FILE_BEGIN
    call SetFilePointerEx

    mov rsp, rbp
    pop rbp
    ret

_set_pointer_end:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    xor rdx, rdx
    lea r8, [rel FILE_MANAGER_ACTIVE_FILE_POINTER]
    mov r9, FILE_END
    call SetFilePointerEx

    mov rsp, rbp
    pop rbp
    ret

_set_pointer_start:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    xor rdx, rdx
    lea r8, [rel FILE_MANAGER_ACTIVE_FILE_POINTER]
    mov r9, FILE_BEGIN
    call SetFilePointerEx

    mov rsp, rbp
    pop rbp
    ret

_read:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    ; Expect pointer to string to load read chars into in RCX.
    ; Expect number of bytes to read in RDX.
    mov r8, rdx
    mov rdx, rcx

    mov rcx, [rel FILE_MANAGER_PTR]
    mov rcx, [rcx + file_manager.file_handle]
    lea r9, [rel FILE_MANAGER_BYTES_READ]
    mov qword [rsp + 32], 0
    call ReadFile

    mov rsp, rbp
    pop rbp
    ret

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
    lea r9, [rel FILE_MANAGER_BYTES_WRITTEN]
    mov qword [rsp + 32], 0
    call WriteFile

    mov rsp, rbp
    pop rbp
    ret

_get_name:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect pointer to buffer to save name into in RCX.
    ; Expect index of desired record in RDX
    mov [rbp - 8], rcx

    mov rcx, rdx
    mov rdx, FILE_NAME_OFFSET
    call _set_pointer

    mov rcx, [rbp - 8]
    mov rdx, FILE_NAME_SIZE
    call _read

    mov rax, [rbp - 8]
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

    call _set_pointer_start

    lea rcx, [rel FILE_MANAGER_HEADER]
    mov rdx, HEADER_SIZE
    call _read
    test eax, eax
    jz .init_header

    mov eax, [rel FILE_MANAGER_HEADER]
    cmp eax, [rel magic]
    jne .init_header

    movzx eax, word [rel FILE_MANAGER_HEADER + 8]
    cmp ax, FILE_RECORD_SIZE
    jne .init_header

    xor rax, rax
    jmp .complete

.init_header:
    call _set_pointer_start

    lea rcx, [rel header_template]
    mov rdx, HEADER_SIZE
    call _write

    xor rax, rax

.complete:
    mov r15, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret