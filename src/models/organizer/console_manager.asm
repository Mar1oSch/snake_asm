%include "../include/organizer/console_manager_struc.inc"

global console_manager_new, console_manager_destroy, console_manager_clean_console

section .rodata
    constructor_name db "console_manager", 13, 10, 0
    debug_print db "Width: %u, height: %d", 13, 10, 0
section .bss
    CONSOLE_MANAGER_PTR resq 1

section .text
    extern malloc
    extern free
    extern malloc_failed, object_not_created
    extern GetStdHandle, printf
    extern SetConsoleCursorPosition, WriteConsoleA
    extern GetConsoleScreenBufferInfo, FillConsoleOutputCharacterA
    extern printf

console_manager_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    jne .complete

    mov rcx, console_manager_size
    call malloc
    mov [rel CONSOLE_MANAGER_PTR], rax

    mov rcx, -11
    call GetStdHandle
    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov [rcx + console_manager.handle], rax

.complete:
    mov rax, [rel CONSOLE_MANAGER_PTR]
    mov rsp, rbp
    pop rbp
    ret

console_manager_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je @object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

; @set_cursor_position:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 40

;     cmp qword [rel CONSOLE_MANAGER_PTR], 0
;     je @object_failed

;     ; Expect COORD struct (2 words) in rdx.
;     mov rcx, [rel CONSOLE_MANAGER_PTR]
;     xor rdx, rdx
;     mov dx, 0
;     shl rdx, 16
;     mov dx, 0
;     call SetConsoleCursorPosition

;     mov rsp, rbp
;     pop rbp
;     ret

; @write_char:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 40

;     cmp qword [rel CONSOLE_MANAGER_PTR], 0
;     je @object_failed

;     ; Expect pointer to char in rdx.
;     mov rcx, [rel CONSOLE_MANAGER_PTR]
;     lea rdx, [rel debug_char]
;     mov r8, 40
;     mov r9, 0
;     xor rax, rax
;     call WriteConsoleA

;     mov rsp, rbp
;     pop rbp
;     ret

;;;;;; ERROR HANDLING ;;;;;;
@object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

@malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret