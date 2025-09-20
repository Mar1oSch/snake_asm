%include "../include/organizer/console_manager_struc.inc"

global console_manager_new, console_manager_destroy, console_manager_clean_console

section .rodata
    constructor_name db "console_manager", 13, 10, 0
    debug_string db "Width: %d, Height: %d", 13, 10, 0
    result db "%d * %d is %d", 13, 10, 0

section .bss
    CONSOLE_MANAGER_PTR resq 1
    CONSOLE_MANAGER_BUFFER_SIZE resw 2
    FILL_CONSOLE_PTR resq 1

section .text
    extern malloc
    extern free
    extern cm_malloc_failed, object_not_created
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

    call empty_console

.complete:
    mov rax, [rel CONSOLE_MANAGER_PTR]
    mov rsp, rbp
    pop rbp
    ret


get_buffer_size:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je cm_object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rcx + console_manager.handle]
    lea rdx, [rel CONSOLE_MANAGER_BUFFER_SIZE]
    call GetConsoleScreenBufferInfo

    xor rax, rax
    mov eax, dword [rel CONSOLE_MANAGER_BUFFER_SIZE]

    mov rsp, rbp
    pop rbp
    ret

empty_console:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je cm_object_failed

    call get_buffer_size

    mov word[rbp- 8], ax
    shr rax, 16
    mov word[rbp - 16], ax

    mov rdx, [rel CONSOLE_MANAGER_PTR]
    mov rcx, [rdx + console_manager.handle]
    mov rdx, " "
    movzx r8, word [rbp - 8]
    movzx r9, word [rbp - 16]
    imul r8, r9
    xor r9, r9
    lea r10, [rel FILL_CONSOLE_PTR]
    mov qword [rbp - 24], r10
    call FillConsoleOutputCharacterA

    mov rsp, rbp
    pop rbp
    ret

; set_cursor_position:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 40

;     cmp qword [rel CONSOLE_MANAGER_PTR], 0
;     je cm_object_failed

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

; write_char:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 40

;     cmp qword [rel CONSOLE_MANAGER_PTR], 0
;     je cm_object_failed

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

console_manager_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel CONSOLE_MANAGER_PTR], 0
    je  cm_object_failed

    mov rcx, [rel CONSOLE_MANAGER_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

;;;;;; ERROR HANDLING ;;;;;;
cm_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

cm_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call cm_malloc_failed

    mov rsp, rbp
    pop rbp
    ret