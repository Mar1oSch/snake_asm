%include "../include/organizer/file_manager_struc.inc"

global file_manager_new, file_manager_destroy
section .rodata
    leaderboard_file_name db "leaderboard.txt", 0

    GENERIC_WRITE equ 0x40000000
    GENERIC_READ equ 0x80000000
    FILE_SHARE_WRITE equ 0x00000002
    OPEN_ALWAYS equ 4
    FILE_ATTRIBUTE_NORMAL equ 0x80
section .bss
    FILE_MANAGER_PTR resq 1

section .text
    extern malloc, free
    extern CreateFileA, CloseHandle
    extern ReadFile, WriteFile

file_manager_new:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    cmp qword [rel FILE_MANAGER_PTR], 0
    jne .complete

    mov rcx, file_manager_size
    call malloc
    mov [rel FILE_MANAGER_PTR], rax

    lea rcx, [rel leaderboard_file_name]
    mov rdx, GENERIC_READ | GENERIC_WRITE
    mov r8, FILE_SHARE_WRITE
    mov r9, 0
    mov dword [rsp + 32], OPEN_ALWAYS
    mov dword [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov dword [rsp + 48], 0
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

file_manager_write:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    